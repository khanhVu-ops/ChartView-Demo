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
    private var isDragging = false
    private var stickPanWidth: CGFloat = 10
    private var stickPanHeight: CGFloat = 18

    private let lineColor: UIColor = .red
    private let fillColor: UIColor = .red.withAlphaComponent(0.6)
    weak var delegate: ControlViewDelegate?
     
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpUI()
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
    }
    
    func updateOverlay(_ update: [ChartPointModel]) {
        let filtered = update
        guard let firstIndex = data.firstIndex(where: {$0.timeStamp == filtered.first?.timeStamp}) else {
            return
        }
        let minX = (CGFloat(firstIndex) / CGFloat(data.count - 1)) * (bounds.width - stickPanWidth) + stickPanWidth / 2
        let newWidth = (CGFloat(filtered.count) / CGFloat(data.count)) * (bounds.width - stickPanWidth)
        overlayView.frame = .init(x: minX, y: 0, width: newWidth, height: bounds.height)
        updateHandlePositions()
    }
    
    private func configureDataSet(_ dataSet: LineChartDataSet) {
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
    
    private func resetOverlayPosition() {
        overlayView.frame = .init(x: stickPanWidth/2, y: 0, width: bounds.width - stickPanWidth, height: bounds.height)
        updateHandlePositions()
    }
    
    private func updateHandlePositions() {
        leftHandleView.center = CGPoint(x: overlayView.frame.minX, y: bounds.height / 2)
        rightHandleView.center = CGPoint(x: overlayView.frame.maxX, y: bounds.height / 2)
    }
}

private extension ControlView {
    func setUpUI() {
        setUpBgChartView()
        setUpOverlayDragable()
        setupTapGesture()
    }
    
    func setUpBgChartView() {
        addSubview(bgChartView)
        bgChartView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(stickPanWidth/2)
            make.top.bottom.equalToSuperview()
        }
        
        configureChartView()
    }
    
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
    
    func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        bgChartView.addGestureRecognizer(tapGesture)
    }

    
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
    
    @objc func leftPanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        
        if gesture.state == .began {
            isDragging = true
            overlayView.backgroundColor = .blue.withAlphaComponent(0.4)
        } else if gesture.state == .changed {
            // Calculate new left edge position
            let newLeftX = max(stickPanWidth/2, min(overlayView.frame.maxX - stickPanWidth, leftHandleView.center.x + translation.x))
            
            // Update overlay frame
            let newWidth = overlayView.frame.maxX - newLeftX
            overlayView.frame = CGRect(
                x: newLeftX,
                y: overlayView.frame.minY,
                width: newWidth,
                height: overlayView.frame.height
            )
            
            // Update handle position
            leftHandleView.center = CGPoint(x: newLeftX, y: leftHandleView.center.y)
            
            gesture.setTranslation(.zero, in: self)
        } else if gesture.state == .ended {
            isDragging = false
            UIView.animate(withDuration: 0.2) {
                self.overlayView.backgroundColor = .blue.withAlphaComponent(0.3)
            }
            notifyRangeChange()
        }
    }
    
    @objc func rightPanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        
        if gesture.state == .began {
            isDragging = true
            overlayView.backgroundColor = .blue.withAlphaComponent(0.4)
        } else if gesture.state == .changed {
            // Calculate new right edge position
            let newRightX = min(bounds.width - stickPanWidth/2, max(overlayView.frame.minX + stickPanWidth, rightHandleView.center.x + translation.x))
            
            // Update overlay frame
            let newWidth = newRightX - overlayView.frame.minX
            overlayView.frame = CGRect(
                x: overlayView.frame.minX,
                y: overlayView.frame.minY,
                width: newWidth,
                height: overlayView.frame.height
            )
            
            // Update handle position
            rightHandleView.center = CGPoint(x: newRightX, y: rightHandleView.center.y)
            
            gesture.setTranslation(.zero, in: self)
        } else if gesture.state == .ended {
            isDragging = false
            UIView.animate(withDuration: 0.2) {
                self.overlayView.backgroundColor = .blue.withAlphaComponent(0.3)
            }
            notifyRangeChange()
        }
    }
    
    @objc func overlayPanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        
        if gesture.state == .began {
            isDragging = true
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
            isDragging = false
            UIView.animate(withDuration: 0.2) {
                self.overlayView.backgroundColor = .blue.withAlphaComponent(0.3)
            }
            notifyRangeChange()
        }
    }
    
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
        }

        notifyRangeChange()
    }
    
    private func notifyRangeChange() {
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
    
    private func getStrideData(_ data: [ChartPointModel], step: Int) -> [ChartPointModel] {
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
}
