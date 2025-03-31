//
//  ChartView.swift
//  ChartDemo
//
//  Created by Khanh Vu on 25/3/25.
//

import UIKit
import DGCharts
import SnapKit

final class ChartView: UIView {
    private var chartView: LineChartView!
    private var data: [ChartPointModel] = []
    var tickMarksView: TickMarksView!
    
    // Add crosshair views
    private var markerInfoView: UIView!
    private var dateLabel: UILabel!
    private var peLabel: UILabel!
    private var indexLabel: UILabel!

    //MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpUI()
    }
}

extension ChartView {
    func setUpUI() {
        if let chartModel = ChartModel.loadFromFile(named: "chart") {
            // Use the parsed data
            print("Success: \(chartModel.success)")
            print("Message: \(chartModel.message)")
            
            // Access chart data
            let dataPoints = chartModel.data.dataChart
            print("Number of data points: \(dataPoints.count)")
            
            // Access current finance data
            let currentFinance = chartModel.data.nowDataFinance
            print("Current PE: \(currentFinance.pe)")
            
            // Init chartView
            DispatchQueue.main.async {
                self.data = getStrideData(dataPoints, step: 100)
                self.setUpCharView()
            }
        } else {
            print("Failed to load chart data")
        }
    }
    
    func setUpCharView() {
        chartView = LineChartView()
        addSubview(chartView)
        chartView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        chartView.delegate = self

        configureLineChart()
        configData()
        
        // Initialize tickMarksView
        tickMarksView = TickMarksView()
        tickMarksView.backgroundColor = .clear
        addSubview(tickMarksView)
        tickMarksView.snp.makeConstraints { make in
            make.top.equalTo(chartView.snp.bottom).offset(-10)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-40) // Above the period selector
        }
        
        // Set initial tick positions and labels
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let (positions, labels) = self.getSelectedXAxisPositions()
            self.tickMarksView.tickPositions = positions
            self.tickMarksView.tickLabels = labels
            self.tickMarksView.setNeedsDisplay()
        }
    }
    
    func getSelectedXAxisPositions() -> ([CGFloat], [String]) {
        guard let data = chartView.data?.first else {
            return ([], [])
        }
        var positions: [CGFloat] = []
        var labels: [String] = []
        let valueIndex: Int = self.data.count / 9
        let valueIndexFirst : Int = self.data.count % 9
        for i in 0...8
        {
            let indexShow = valueIndexFirst + (i * valueIndex)
            let entry = data.entryForIndex(indexShow)
            let xValue = entry?.x ?? 0
            let pixelPosition = chartView.getTransformer(forAxis: .left).pixelForValues(x: xValue, y: 0)
            let adjustedX = pixelPosition.x - chartView.viewPortHandler.contentLeft
            positions.append(adjustedX)
            labels.append(formattedDate(Int64(entry?.x ?? 0)))
        }
        return (positions, labels)
    }
    
    func formattedDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/yyyy"
        return dateFormatter.string(from: date)
    }
    
    func configureLineChart() {
        // Basic chart configuration
        chartView.rightAxis.enabled = true
        chartView.leftAxis.enabled = true
        chartView.xAxis.enabled = true
        chartView.legend.enabled = false
        chartView.chartDescription.enabled = false
        
        // Configure navigation features
        chartView.scaleXEnabled = false
        chartView.scaleYEnabled = false
        chartView.dragEnabled = true
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = false
        
        
        chartView.highlightPerDragEnabled = true
        chartView.highlightPerTapEnabled = true
        // Configure X-Axis
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.drawLabelsEnabled = false
        xAxis.drawGridLinesEnabled = false
        xAxis.axisLineWidth = 0.5
        xAxis.axisLineColor = .black

        // Configure Left Y-Axis (PE)
        let leftAxis = chartView.leftAxis
        leftAxis.drawAxisLineEnabled = false
        leftAxis.labelTextColor = UIColor(red: 0/255, green: 71/255, blue: 121/255, alpha: 1)
        leftAxis.drawGridLinesEnabled = true
        leftAxis.gridColor = UIColor.lightGray.withAlphaComponent(0.5)
        leftAxis.granularityEnabled = true
        
        // Configure Right Y-Axis (Index)
        let rightAxis = chartView.rightAxis
        rightAxis.drawAxisLineEnabled = false
        rightAxis.labelTextColor = UIColor(red: 196/255, green: 26/255, blue: 22/255, alpha: 1)
        rightAxis.drawGridLinesEnabled = false
        rightAxis.granularityEnabled = true
        
        // Add info view at the top
        addInfoView()
        
        // Add period selector at the bottom
        addPeriodSelectorView()
    }

    func configData() {
        // Data set for PE line
        let peDataEntry = data.map {
            ChartDataEntry(x: Double($0.timeStamp), y: $0.pe)
        }
        
        // Data set for Index line
        let indexDataEntry = data.map {
            ChartDataEntry(x: Double($0.timeStamp), y: $0.index)
        }
        
        // Configure PE data set (blue line)
        let peDataSet = LineChartDataSet(entries: peDataEntry, label: "PE")
        peDataSet.axisDependency = .left
        peDataSet.drawCirclesEnabled = false
        peDataSet.drawValuesEnabled = false
        peDataSet.mode = .cubicBezier  // Smooth curves like in the image
        peDataSet.highlightEnabled = true
        peDataSet.setColor(UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1))
        peDataSet.setCircleColor(.green)
        peDataSet.lineWidth = 1
        peDataSet.circleRadius = 3
        peDataSet.fillAlpha = 65/255
        peDataSet.fillColor = UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1)
        peDataSet.highlightColor = UIColor(red: 244/255, green: 117/255, blue: 117/255, alpha: 1)
        peDataSet.drawCircleHoleEnabled = false
//        peDataSet.drawHorizontalHighlightIndicatorEnabled = false
//        peDataSet.drawVerticalHighlightIndicatorEnabled = false // We'll handle the highlight manually
        
        // Configure Index data set (red line)
        let indexDataSet = LineChartDataSet(entries: indexDataEntry, label: "Index")
        indexDataSet.axisDependency = .right
        indexDataSet.setColor(UIColor(red: 196/255, green: 26/255, blue: 22/255, alpha: 1))
        indexDataSet.lineWidth = 1.5
        indexDataSet.drawCirclesEnabled = false
        indexDataSet.drawValuesEnabled = false
        indexDataSet.mode = .cubicBezier  // Smooth curves like in the image
        indexDataSet.highlightEnabled = true
//        indexDataSet.drawHorizontalHighlightIndicatorEnabled = false
//        indexDataSet.drawVerticalHighlightIndicatorEnabled = false // We'll handle the highlight manually
        
        let data: LineChartData = [peDataSet, indexDataSet]
        chartView.data = data
        chartView.data!.isHighlightEnabled = true
    }

    // Add an info view at the top to display date and values
    func addInfoView() {
        let infoView = UIView()
        infoView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        infoView.layer.cornerRadius = 5
        infoView.layer.borderWidth = 1
        infoView.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
        addSubview(infoView)
        
        infoView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(10)
            make.height.equalTo(30)
        }
        
        dateLabel = UILabel()
        dateLabel.text = "Ngày: 14/1/2019"
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        infoView.addSubview(dateLabel)
        
        dateLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
        }
        
        peLabel = UILabel()
        peLabel.text = "• PE: 14.87"
        peLabel.font = UIFont.systemFont(ofSize: 12)
        peLabel.textColor = UIColor(red: 0/255, green: 71/255, blue: 121/255, alpha: 1)
        infoView.addSubview(peLabel)
        
        peLabel.snp.makeConstraints { make in
            make.leading.equalTo(dateLabel.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
        }
        
        indexLabel = UILabel()
        indexLabel.text = "• Index: 904.87"
        indexLabel.font = UIFont.systemFont(ofSize: 12)
        indexLabel.textColor = UIColor(red: 196/255, green: 26/255, blue: 22/255, alpha: 1)
        infoView.addSubview(indexLabel)
        
        indexLabel.snp.makeConstraints { make in
            make.leading.equalTo(peLabel.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-10)
        }
    }

    // Add period selector at the bottom
    func addPeriodSelectorView() {
        let periodSelectorView = UIView()
        periodSelectorView.backgroundColor = .white
        addSubview(periodSelectorView)
        
        periodSelectorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(40)
        }
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 5
        periodSelectorView.addSubview(stackView)
        
        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(10)
            make.top.bottom.equalToSuperview().inset(5)
        }
        
        let periods = ["1w", "1m", "3m", "6m", "YTD", "1y", "5y", "All"]
        
        for (index, period) in periods.enumerated() {
            let button = UIButton()
            button.setTitle(period, for: .normal)
            button.setTitleColor(.darkGray, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            button.tag = index
            button.addTarget(self, action: #selector(periodButtonTapped(_:)), for: .touchUpInside)
            
            // Highlight the "All" button by default based on the image
            if period == "All" {
                button.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
                button.layer.cornerRadius = 5
            }
            
            stackView.addArrangedSubview(button)
        }
    }

    @objc func periodButtonTapped(_ sender: UIButton) {
        // Reset all buttons
        if let stackView = sender.superview as? UIStackView {
            for case let button as UIButton in stackView.arrangedSubviews {
                button.backgroundColor = .clear
            }
        }
        
        // Highlight selected button
        sender.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        sender.layer.cornerRadius = 5
        
        // Update chart data based on selected period
        let period = sender.tag
        
        switch period {
        case 0: // 1w
            filterDataForPeriod(days: 7)
        case 1: // 1m
            filterDataForPeriod(days: 30)
        case 2: // 3m
            filterDataForPeriod(days: 90)
        case 3: // 6m
            filterDataForPeriod(days: 180)
        case 4: // YTD
            filterDataYearToDate()
        case 5: // 1y
            filterDataForPeriod(days: 365)
        case 6: // 5y
            filterDataForPeriod(days: 365 * 5)
        case 7: // All
            useAllData()
        default:
            break
        }
    }

    func filterDataForPeriod(days: Int) {
        let currentDate = Date()
        let calendar = Calendar.current
        let pastDate = calendar.date(byAdding: .day, value: -days, to: currentDate)!
        let pastTimestamp = Int(pastDate.timeIntervalSince1970)
        
        let filteredData = self.data.filter { $0.timeStamp >= pastTimestamp }
        updateChart(with: filteredData)
    }

    func filterDataYearToDate() {
        let currentDate = Date()
        let calendar = Calendar.current
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: currentDate))!
        let startTimestamp = Int(startOfYear.timeIntervalSince1970)
        
        let filteredData = self.data.filter { $0.timeStamp >= startTimestamp }
        updateChart(with: filteredData)
    }

    func useAllData() {
        updateChart(with: self.data)
    }

    func updateChart(with filteredData: [ChartPointModel]) {
        // Update PE data
        let peDataEntry = filteredData.map {
            ChartDataEntry(x: Double($0.timeStamp), y: $0.pe)
        }
        
        // Update Index data
        let indexDataEntry = filteredData.map {
            ChartDataEntry(x: Double($0.timeStamp), y: $0.index)
        }
        
        if let peDataSet = chartView.data?.dataSets[0] as? LineChartDataSet {
            peDataSet.replaceEntries(peDataEntry)
        }
        
        if let indexDataSet = chartView.data?.dataSets[1] as? LineChartDataSet {
            indexDataSet.replaceEntries(indexDataEntry)
        }
        

        // Update X-axis tick marks
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.chartView.notifyDataSetChanged()
            self.chartView.fitScreen()
            
            let (positions, labels) = self.getSelectedXAxisPositions()
            self.tickMarksView.tickPositions = positions
            self.tickMarksView.tickLabels = labels
            self.tickMarksView.setNeedsDisplay()
        }
    }

    // Update info labels with highlighted values
    func updateInfoLabels(with entry: ChartDataEntry, highlight: Highlight) {
        let peValue: Double
        let indexValue: Double
        
        // Get both values at the tapped position
        if highlight.dataSetIndex == 0 { // PE dataset
            peValue = entry.y
            // Find index value at same x position
            if let indexEntry = chartView.data?.dataSets[1].entryForXValue(entry.x, closestToY: entry.y) {
                indexValue = indexEntry.y
            } else {
                indexValue = 0
            }
        } else { // Index dataset
            indexValue = entry.y
            // Find PE value at same x position
            if let peEntry = chartView.data?.dataSets[0].entryForXValue(entry.x, closestToY: entry.y) {
                peValue = peEntry.y
            } else {
                peValue = 0
            }
        }
        
        let date = Date(timeIntervalSince1970: entry.x)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let dateString = dateFormatter.string(from: date)
        
        // Update top info view
        dateLabel.text = "Ngày: \(dateString)"
        peLabel.text = "• PE: \(String(format: "%.2f", peValue))"
        indexLabel.text = "• Index: \(String(format: "%.2f", indexValue))"
    }
}

// MARK: - Delegate
extension ChartView: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        NSLog("chartValueSelected");
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        NSLog("chartValueNothingSelected");
    }
    
    func chartScaled(_ chartView: ChartViewBase, scaleX: CGFloat, scaleY: CGFloat) {
        NSLog("chartScaled");

    }
    
    func chartTranslated(_ chartView: ChartViewBase, dX: CGFloat, dY: CGFloat) {
        NSLog("chartTranslated");

    }
    
    func chartViewDidEndPanning(_ chartView: ChartViewBase) {
        NSLog("chartViewDidEndPanning");

    }
}
