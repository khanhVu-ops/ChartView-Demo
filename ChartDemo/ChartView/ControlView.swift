//
//  ControlView.swift
//  ChartDemo
//
//  Created by Khánh Vũ on 31/3/25.
//

import UIKit
import DGCharts
import SnapKit

protocol ControlViewDelegate: AnyObject {
    func controlView(_ controlView: ControlView, didUpdateRange range: (start: Double, end: Double))
}

final class ControlView: UIView {
    private var bgChartView = LineChartView()
    private var overlayView: UIView!
    private var leftHandleView: UIView!
    private var rightHandleView: UIView!
    
    private var data: [ChartPointModel] = []
    private var stickPanWidth: CGFloat = 10
    private var stickPanHeight: CGFloat = 18
    
    // Save ratio of overlay to relayout when device change orientation
    private var currentOverlayRatios: (start: CGFloat, end: CGFloat) = (0, 1)
    
    // Line chart bgr color
    private let lineColor: UIColor = .red
    // Fill gradient color chart
    private let fillColor: UIColor = .red.withAlphaComponent(0.6)
    
    // Delegate
    weak var delegate: ControlViewDelegate?
     
    //MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpUI()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Update overlay frame if needed
        if overlayView.frame == CGRect.zero {
            resetOverlayPosition()
        }
        
        // Update handle positions
        updateHandlePositions()
    }
    
    // MARK: - Public method
    func bindChartData(_ data: [ChartPointModel]) {
        self.data = data
        let peDataEntry = getStrideData(data, step: 10).map {
            ChartDataEntry(x: Double($0.timeStamp), y: $0.pe)
        }
        
        let peDataSet = LineChartDataSet(entries: peDataEntry, label: "PE")
        configureDataSet(peDataSet)
        bgChartView.data = LineChartData(dataSet: peDataSet)
        
        // Reset overlay position when new data is bound
        layoutIfNeeded()
        resetOverlayPosition()
        updateHandlePositions()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.drawTimeLineBackgroundChart()
        }
    }
    
    func updateOverlay(_ update: [ChartPointModel]) {
        let filtered = update
        guard let firstIndex = data.firstIndex(where: {$0.timeStamp == filtered.first?.timeStamp}) else {
            return
        }
        let minX = (CGFloat(firstIndex) / CGFloat(data.count - 1)) * (bounds.width - stickPanWidth) + stickPanWidth / 2
        let newWidth = (CGFloat(filtered.count) / CGFloat(data.count)) * (bounds.width - stickPanWidth)
        overlayView.frame = .init(x: minX, y: 0, width: newWidth, height: bounds.height)
        
        updateCurrentRatio()
        updateHandlePositions()
    }
}

//MARK: - Private Method
private extension ControlView {
    func setUpUI() {
        setUpBgChartView()
        setUpOverlayDragable()
        setupTapGesture()
        setupOrientationObserver()
    }
    
    // Init charview
    func setUpBgChartView() {
        addSubview(bgChartView)
        bgChartView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(stickPanWidth/2)
            make.top.bottom.equalToSuperview()
        }
        
        configureChartView()
    }
    
    // Init overlay view and stick dragable view
    func setUpOverlayDragable() {
        // Create and configure overlay view
        overlayView = UIView()
        overlayView.backgroundColor = .blue.withAlphaComponent(0.3)
        addSubview(overlayView)
        
        // Create draggable handles
        leftHandleView = createStickDragView()
        leftHandleView.isUserInteractionEnabled = true
        leftHandleView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(leftPanGesture(_:))))
        addSubview(leftHandleView)
        
        rightHandleView = createStickDragView()
        rightHandleView.isUserInteractionEnabled = true
        rightHandleView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(rightPanGesture(_:))))
        addSubview(rightHandleView)
        
        // Add a drag gesture to the overlay view itself for moving the entire selection
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(overlayPanGesture(_:)))
        overlayView.addGestureRecognizer(panGesture)
    }
    
    // Create Stick DragableView
    func createStickDragView() -> UIView {
        let v = UIView()
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.darkGray.cgColor
        v.backgroundColor = .lightGray.withAlphaComponent(0.3)
        v.frame = CGRect(x: 0, y: 0, width: stickPanWidth, height: stickPanHeight)
        
        // Add a vertical line in the center to make it look like a handle
        let lineLayer1 = CALayer()
        lineLayer1.backgroundColor = UIColor.darkGray.cgColor
        lineLayer1.frame = .init(x: stickPanWidth / 2 - 2, y: 4, width: 1, height: stickPanHeight - 8)
        
        let lineLayer2 = CALayer()
        lineLayer2.backgroundColor = UIColor.darkGray.cgColor
        lineLayer2.frame = .init(x: stickPanWidth / 2 + 1, y: 4, width: 1, height: stickPanHeight - 8)
        
        v.layer.addSublayer(lineLayer1)
        v.layer.addSublayer(lineLayer2)
        return v
    }
    
    // Add tap gesture
    func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        bgChartView.addGestureRecognizer(tapGesture)
    }
    
    // Draw time line background chart
    func drawTimeLineBackgroundChart() {
        let prefixName = "time_line_bgr_chart_"
        // Remove layer
        bgChartView.layer.sublayers?.forEach { sub in
            if sub.name?.hasPrefix(prefixName) == true {
                sub.removeFromSuperlayer()
            }
        }
        
        let indices = findFirstIndicesOfNewYears(data.map{ $0.timeStamp })
        let years = indices.map { getYearFromTimestamp(data[$0].timeStamp) }
        let xValues = indices.map{
            CGFloat($0) / CGFloat(data.count - 1) * CGFloat(bgChartView.bounds.width)
        }
        
        // draw top line
        let topLayer = CALayer()
        topLayer.backgroundColor = UIColor.lightGray.cgColor
        topLayer.frame = .init(x: 0, y: 0, width: bgChartView.frame.width, height: 0.5)
        topLayer.name = prefixName + "top"
        bgChartView.layer.addSublayer(topLayer)
        
        // draw time line
        for (index, xValue) in xValues.enumerated() {
            // Vertical line
            let lineLayer = CALayer()
            lineLayer.backgroundColor = UIColor.lightGray.cgColor
            lineLayer.frame = .init(x: xValue, y: 0, width: 1, height: bgChartView.frame.height)
            lineLayer.name = prefixName + "line_\(index)"
            bgChartView.layer.addSublayer(lineLayer)

            // Year label
            let yearString = "\(years[index])"
            
            let timeLabel = CATextLayer()
            timeLabel.string = yearString
            timeLabel.fontSize = 12
            timeLabel.foregroundColor = UIColor.darkGray.cgColor
            timeLabel.alignmentMode = .center
            timeLabel.contentsScale = UIScreen.main.scale
            timeLabel.name = prefixName + "label_\(index)"

            // Calculate text width to center properly
            let textWidth = yearString.size(withAttributes: [.font: UIFont.systemFont(ofSize: 12)]).width
            
            timeLabel.frame = CGRect(x: xValue + 2, y: 8, width: textWidth, height: 12)
            bgChartView.layer.addSublayer(timeLabel)
        }
    }
    
    // Configure chart view
    func configureChartView() {
        bgChartView.rightAxis.enabled = false
        bgChartView.leftAxis.enabled = false
        bgChartView.xAxis.enabled = false
        bgChartView.legend.enabled = false
        bgChartView.chartDescription.enabled = false
        bgChartView.scaleXEnabled = false
        bgChartView.scaleYEnabled = false
        bgChartView.dragEnabled = false
        bgChartView.pinchZoomEnabled = false
        bgChartView.doubleTapToZoomEnabled = false
        bgChartView.backgroundColor = .clear
        
        bgChartView.setViewPortOffsets(left: 0, top: 0, right: 0, bottom: 0)
    }
    
    // Configure chart dataset
    func configureDataSet(_ dataSet: LineChartDataSet) {
        dataSet.axisDependency = .left
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.mode = .cubicBezier  // Smooth curves like in the image
        dataSet.highlightEnabled = false
        dataSet.setColor(lineColor)
        dataSet.lineWidth = 0.5
        dataSet.fillAlpha = 65/255
        dataSet.fillColor = fillColor
        dataSet.drawCircleHoleEnabled = false
        dataSet.drawFilledEnabled = true
    }
    
    // Reset overlay view position
    func resetOverlayPosition() {
        let defaultWidth = bounds.width - stickPanWidth
        overlayView.frame = .init(x: stickPanWidth/2, y: 0, width: defaultWidth, height: bounds.height)
        updateCurrentRatio()
        updateHandlePositions()
    }
    
    // Update stick dragable view position
    func updateHandlePositions() {
        leftHandleView.center = CGPoint(x: overlayView.frame.minX, y: bounds.height / 2)
        rightHandleView.center = CGPoint(x: overlayView.frame.maxX, y: bounds.height / 2)
    }
    
    // Save current ratios
    func updateCurrentRatio() {
        currentOverlayRatios = (
            start: (overlayView.frame.minX - (stickPanWidth / 2)) / (bounds.width - stickPanWidth),
            end: (overlayView.frame.maxX - (stickPanWidth / 2)) / (bounds.width - stickPanWidth)
        )
    }
    
    // Notification when range change to update chart view
    func notifyRangeChange() {
        guard !data.isEmpty else { return }
        
        let totalWidth = bounds.width
        let startPercentage = overlayView.frame.minX / totalWidth
        let endPercentage = overlayView.frame.maxX / totalWidth
        
        let startIndex = Int(startPercentage * Double(data.count))
        let endIndex = Int(endPercentage * Double(data.count))
        
        let safeStartIndex = max(0, min(data.count - 1, startIndex))
        let safeEndIndex = max(0, min(data.count - 1, endIndex))
        
        let startTime = Double(data[safeStartIndex].timeStamp)
        let endTime = Double(data[safeEndIndex].timeStamp)
        
        delegate?.controlView(self, didUpdateRange: (start: startTime, end: endTime))
    }
    
    //MARK: - Helper Method
    
    // Get Stride Data to resize number data draw background chart
    func getStrideData(_ data: [ChartPointModel], step: Int) -> [ChartPointModel] {
        guard step > 0, !data.isEmpty else { return data }
        var result: [ChartPointModel] = []
        
        // Always include first point
        result.append(data[0])
        
        // Add points at regular intervals
        for i in stride(from: step, to: data.count - 1, by: step) {
            result.append(data[i])
        }
        
        // Add the last point if it's not already included
        if result.last?.timeStamp != data.last?.timeStamp {
            result.append(data.last!)
        }
        
        return result
    }
    
    // Find first indices of new years to draw time background chart
    func findFirstIndicesOfNewYears(_ timestamps: [Int64]) -> [Int] {
        guard !timestamps.isEmpty else { return [] }
        
        var firstIndicesOfYears: [Int] = []
        var currentYear: Int = -1
        
        for (index, timestamp) in timestamps.enumerated() {
            let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
            let calendar = Calendar.current
            let year = calendar.component(.year, from: date)
            
            // Nếu đây là năm mới chưa xuất hiện trước đó
            if year != currentYear && year % 2 == 0 {
                firstIndicesOfYears.append(index)
                currentYear = year
            }
        }
        
        return firstIndicesOfYears
    }
}

// MARK: - Objc method
private extension ControlView {
    // Left Stick panable drag handler
    @objc func leftPanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        
        if gesture.state == .began {
            overlayView.backgroundColor = .blue.withAlphaComponent(0.4)
        } else if gesture.state == .changed {
            // Calculate new left edge position
            let newLeftX = max(stickPanWidth/2, min(bounds.width - stickPanWidth/2, leftHandleView.center.x + translation.x))
            
            // Update overlay frame
            let rightX = rightHandleView.center.x
            let newWidth = abs(rightX - newLeftX)
            overlayView.frame = CGRect(
                x: min(rightX, newLeftX),
                y: overlayView.frame.minY,
                width: newWidth,
                height: overlayView.frame.height
            )
            
            // Update handle position
            leftHandleView.center = CGPoint(x: newLeftX, y: leftHandleView.center.y)
            
            gesture.setTranslation(.zero, in: self)
        } else if gesture.state == .ended {
            UIView.animate(withDuration: 0.2) {
                self.overlayView.backgroundColor = .blue.withAlphaComponent(0.3)
            }
            // Save current ratios
            updateCurrentRatio()
            
            notifyRangeChange()
        }
    }
    
    // Right Stick panable drag handler
    @objc func rightPanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        
        if gesture.state == .began {
            overlayView.backgroundColor = .blue.withAlphaComponent(0.4)
        } else if gesture.state == .changed {
            // Calculate new right edge position
            let newRightX = min(bounds.width - stickPanWidth/2, max(stickPanWidth / 2, rightHandleView.center.x + translation.x))
            
            // Update overlay frame
            let leftX = leftHandleView.center.x
            let newWidth = abs(newRightX - leftX)
            overlayView.frame = CGRect(
                x: min(newRightX, leftX),
                y: overlayView.frame.minY,
                width: newWidth,
                height: overlayView.frame.height
            )
            
            // Update handle position
            rightHandleView.center = CGPoint(x: newRightX, y: rightHandleView.center.y)
            
            gesture.setTranslation(.zero, in: self)
        } else if gesture.state == .ended {
            UIView.animate(withDuration: 0.2) {
                self.overlayView.backgroundColor = .blue.withAlphaComponent(0.3)
            }
            // Save current ratios
            updateCurrentRatio()
            
            notifyRangeChange()
        }
    }
    
    // Overlay View panable drag handler
    
    @objc func overlayPanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        
        if gesture.state == .began {
            overlayView.backgroundColor = .blue.withAlphaComponent(0.4)
        } else if gesture.state == .changed {
            // Calculate new position, ensuring the overlay stays within bounds
            let newX = max(stickPanWidth/2, min(bounds.width - stickPanWidth/2 - overlayView.frame.width, overlayView.frame.minX + translation.x))
            overlayView.frame = CGRect(
                x: newX,
                y: overlayView.frame.minY,
                width: overlayView.frame.width,
                height: overlayView.frame.height
            )
            
            // Update handle positions
            updateHandlePositions()
            
            gesture.setTranslation(.zero, in: self)
        } else if gesture.state == .ended {
            UIView.animate(withDuration: 0.2) {
                self.overlayView.backgroundColor = .blue.withAlphaComponent(0.3)
            }
            // Save current ratios
            updateCurrentRatio()
            notifyRangeChange()
        }
    }
    
    // Tap to move overlay view handler
    @objc func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        let tapLocation = gesture.location(in: self)
        let overlayWidth = overlayView.frame.width
        
        // Calculate new X position for the overlay, ensuring it stays within bounds
        var newX = tapLocation.x - overlayWidth / 2
        newX = max(stickPanWidth/2, min(bounds.width - stickPanWidth / 2 - overlayWidth, newX))
        
        // Animate the movement of the overlay view to the tapped position
        UIView.animate(withDuration: 0.25) {
            self.overlayView.frame.origin.x = newX
            self.updateHandlePositions()
        } completion: { _ in
            self.updateCurrentRatio()
        }
        
        // Save current ratios after animation completes
        
        
        notifyRangeChange()
    }
}


//MARK: Observer Device orientation change
private extension ControlView {
    // Register observer
    func setupOrientationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOrientationChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    @objc func handleOrientationChange() {
        // Đảm bảo view đã được cập nhật size sau khi xoay
        DispatchQueue.main.async {
            self.updateOverlayPositionAfterRotation()
        }
    }

    func updateOverlayPositionAfterRotation() {
        // Tính toán lại vị trí dựa trên tỉ lệ đã lưu
        
        let newStartX = currentOverlayRatios.start * (bounds.width - stickPanWidth)
        let newEndX = currentOverlayRatios.end * (bounds.width - stickPanWidth)
        let newWidth = newEndX - newStartX
        
        // Cập nhật frame của overlay
        overlayView.frame = CGRect(
            x: newStartX + stickPanWidth / 2,
            y: 0,
            width: newWidth,
            height: bounds.height
        )
        
        // Cập nhật vị trí của các handle
        updateHandlePositions()
        drawTimeLineBackgroundChart()
        // Thông báo về sự thay đổi range nếu cần
        notifyRangeChange()
    }
}
