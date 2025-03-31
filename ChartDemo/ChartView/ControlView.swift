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
    private var stickPanWidth: CGFloat = 20
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
            overlayView.frame = .init(x: stickPanWidth/2, y: 0, width: bounds.width - stickPanWidth, height: bounds.height)
        }
    }
    
    func bindChartData(_ data: [ChartPointModel]) {
        self.data = data.reversed()
        let peDataEntry = getStrideData(data, step: 10).map {
            ChartDataEntry(x: Double($0.timeStamp), y: $0.pe)
        }
        
        let peDataSet = LineChartDataSet(entries: peDataEntry, label: "PE")
        configureDataSet(peDataSet)
        bgChartView.data = LineChartData(dataSet: peDataSet)
        
        // Reset overlay position when new data is bound
        layoutIfNeeded()
        resetOverlayPosition()
    }
    
    private func configureDataSet(_ dataSet: LineChartDataSet) {
        dataSet.axisDependency = .left
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.mode = .cubicBezier  // Smooth curves like in the image
        dataSet.highlightEnabled = false
        dataSet.setColor(UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1))
        dataSet.lineWidth = 0.5
        dataSet.fillAlpha = 65/255
        dataSet.fillColor = UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1)
        dataSet.highlightColor = UIColor(red: 244/255, green: 117/255, blue: 117/255, alpha: 1)
        dataSet.drawCircleHoleEnabled = false
        dataSet.drawFilledEnabled = true
    }
    
    private func resetOverlayPosition() {
        overlayView.frame = .init(x: stickPanWidth/2, y: 0, width: bounds.width - stickPanWidth, height: bounds.height)
        updateHandlePositions()
    }
    
    private func updateHandlePositions() {
        leftHandleView.snp.updateConstraints { make in
            make.centerX.equalTo(overlayView.snp.leading)
        }
        
        rightHandleView.snp.updateConstraints { make in
            make.centerX.equalTo(overlayView.snp.trailing)
        }
    }
}

private extension ControlView {
    func setUpUI() {
        setUpBgChartView()
        setUpOverlayDragable()
    }
    
    func setUpBgChartView() {
        addSubview(bgChartView)
        bgChartView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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
        
        // Position handles
        leftHandleView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalTo(overlayView.snp.leading)
            make.width.equalTo(stickPanWidth)
            make.height.equalTo(30)
        }
        
        rightHandleView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalTo(overlayView.snp.trailing)
            make.width.equalTo(stickPanWidth)
            make.height.equalTo(30)
        }
        
        // Add a drag gesture to the overlay view itself for moving the entire selection
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(overlayPanGesture(_:)))
        overlayView.addGestureRecognizer(panGesture)
    }
    
    func createStickDragView() -> UIView {
        let v = UIView()
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.darkGray.cgColor
        v.backgroundColor = .lightGray
        v.layer.cornerRadius = 3
        
        // Add a vertical line in the center to make it look like a handle
        let lineView = UIView()
        lineView.backgroundColor = .darkGray
        v.addSubview(lineView)
        lineView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(2)
            make.height.equalTo(15)
        }
        
        return v
    }
    
    @objc func leftPanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        
        if gesture.state == .began {
            isDragging = true
            overlayView.backgroundColor = .blue.withAlphaComponent(0.4)
        }
        
        let newX = max(stickPanWidth / 2, min(overlayView.frame.maxX - 20, overlayView.frame.minX + translation.x))
        let newWidth = overlayView.frame.maxX - newX
        
        overlayView.frame = CGRect(
            x: newX,
            y: overlayView.frame.minY,
            width: newWidth,
            height: overlayView.frame.height
        )
        
        gesture.setTranslation(.zero, in: self)
//        updateHandlePositions()
        
        if gesture.state == .ended {
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
        }
        
        let minWidth = 20.0
        let maxWidth = bounds.width - stickPanWidth / 2 - overlayView.frame.minX
        let newWidth = max(minWidth, min(maxWidth, overlayView.frame.width + translation.x))
        
        overlayView.frame = CGRect(
            x: overlayView.frame.minX,
            y: overlayView.frame.minY,
            width: newWidth,
            height: overlayView.frame.height
        )
        
        gesture.setTranslation(.zero, in: self)
        updateHandlePositions()
        
        if gesture.state == .ended {
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
        }
        
        // Calculate new position, ensuring the overlay stays within bounds
        let newX = max(stickPanWidth / 2 , min(bounds.width - stickPanWidth/2 - overlayView.frame.width, overlayView.frame.minX + translation.x))
        overlayView.frame = CGRect(
            x: newX,
            y: overlayView.frame.minY,
            width: overlayView.frame.width,
            height: overlayView.frame.height
        )
        
        gesture.setTranslation(.zero, in: self)
        updateHandlePositions()
        
        if gesture.state == .ended {
            isDragging = false
            UIView.animate(withDuration: 0.2) {
                self.overlayView.backgroundColor = .blue.withAlphaComponent(0.3)
            }
            notifyRangeChange()
        }
    }
    
    private func notifyRangeChange() {
        guard !data.isEmpty else { return }
        
        let totalWidth = bounds.width - stickPanWidth
        let startPercentage = (overlayView.frame.minX - stickPanWidth/2) / totalWidth
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
