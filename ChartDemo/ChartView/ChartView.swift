import UIKit
import DGCharts
import SnapKit

final class ChartView: UIView {
    private var chartView: LineChartView!
    private var tickMarksView: TickMarksView!
    private var controlView: ControlView!
    
    private var data: [ChartPointModel] = []
    
    // Crosshair views
    private var markerInfoView: UIView!
    private var dateLabel: UILabel!
    private var peLabel: UILabel!
    private var indexLabel: UILabel!
    
    // Flag to prevent recursive updates
    private var isUpdatingFromControlView = false
    private let highlightPointWidth: CGFloat = 6
    private let highlightPointExpand: CGFloat = 16
    private let peDataSetColor: UIColor = .red
    private let indexDataSetColor: UIColor = UIColor(red: 9/255, green: 19/255, blue: 192/255, alpha: 1)
    
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

//MARK: - Init subviews
private extension ChartView {
    // Add an info view at the top to display date and values
    func addInfoView() {
        markerInfoView = UIView()
        markerInfoView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        markerInfoView.layer.cornerRadius = 5
        markerInfoView.layer.borderWidth = 1
        markerInfoView.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
        addSubview(markerInfoView)
        
        markerInfoView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(10)
            make.height.equalTo(30)
        }
        
        dateLabel = UILabel()
        dateLabel.text = "Ngày: 14/1/2019"
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        markerInfoView.addSubview(dateLabel)
        
        dateLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
        }
        
        peLabel = UILabel()
        peLabel.text = "• PE: 14.87"
        peLabel.font = UIFont.systemFont(ofSize: 12)
        peLabel.textColor = UIColor(red: 0/255, green: 71/255, blue: 121/255, alpha: 1)
        markerInfoView.addSubview(peLabel)
        
        peLabel.snp.makeConstraints { make in
            make.leading.equalTo(dateLabel.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
        }
        
        indexLabel = UILabel()
        indexLabel.text = "• Index: 904.87"
        indexLabel.font = UIFont.systemFont(ofSize: 12)
        indexLabel.textColor = UIColor(red: 196/255, green: 26/255, blue: 22/255, alpha: 1)
        markerInfoView.addSubview(indexLabel)
        
        indexLabel.snp.makeConstraints { make in
            make.leading.equalTo(peLabel.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-10)
        }
    }
    
    func addControlView() {
        controlView = ControlView()
        addSubview(controlView)
        controlView.snp.makeConstraints { make in
            make.top.equalTo(tickMarksView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(25)
        }
        controlView.delegate = self // Set delegate
        controlView.bindChartData(data)
    }
    
    // Initialize tick mark label x axis
    func addTickMarksView() {
        // Initialize tickMarksView
        tickMarksView = TickMarksView()
        tickMarksView.backgroundColor = .clear
        addSubview(tickMarksView)
        tickMarksView.snp.makeConstraints { make in
            make.top.equalTo(chartView.snp.bottom).offset(-10)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(40)
        }
    }
    
    // Update Tick mark label X Axis
    func updateTickMarksAfterChangeData() {
        DispatchQueue.main.async {
            let (positions, labels) = self.getSelectedXAxisPositions()
            self.tickMarksView.tickPositions = positions
            self.tickMarksView.tickLabels = labels
            self.tickMarksView.setNeedsDisplay()
        }
    }

    // Add period selector at the bottom
    func addPeriodSelectorView() {
        let periodSelectorView = UIView()
        periodSelectorView.backgroundColor = .lightGray.withAlphaComponent(0.2)
        periodSelectorView.layer.cornerRadius = 5

        addSubview(periodSelectorView)
        
        periodSelectorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(25)
            make.top.equalTo(controlView.snp.bottom).offset(10)
        }
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 5
        periodSelectorView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.bottom.equalToSuperview()
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
        
        // Set flag to prevent recursive updates
        isUpdatingFromControlView = true
        
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
        
        isUpdatingFromControlView = false
    }
}

extension ChartView {
    func setUpUI() {
        if let chartModel = ChartModel.loadFromFile(named: "chart") {
            // Init chartView
            DispatchQueue.main.async {
                self.data = chartModel.data.dataChart.sorted(by: {$0.timeStamp < $1.timeStamp})
                self.initChartView()
            }
        } else {
            print("Failed to load chart data")
        }
    }
    
    func initChartView() {
        // Initialize chart view
        chartView = LineChartView()
        addSubview(chartView)
        chartView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        chartView.delegate = self
        
        // configure line chart
        configureLineChart()
        
        // configure data chart
        configData()
        
        // Add Mark Axis Label View
        addTickMarksView()
        
        // update tick label x axis after update data
        updateTickMarksAfterChangeData()
        
        // initialize control view
        addControlView()
        
        // Add info view at the top
        addInfoView()
        
        // Add period selector at the bottom
        addPeriodSelectorView()
    }
    
    func getSelectedXAxisPositions() -> ([CGFloat], [String]) {
        guard let data = chartView.data?.first, data.entryCount != 0 else {
            return ([], [])
        }
        var positions: [CGFloat] = []
        var labels: [String] = []
        let valueIndex: Int = max(1, data.entryCount / 9)
        let valueIndexFirst: Int = data.entryCount % 9
        for i in 1...9 {
            let indexShow = min(data.entryCount - 1, valueIndexFirst + (i * valueIndex))
            guard let entry = data.entryForIndex(indexShow) else { continue }
            let xValue = entry.x
            let pixelPosition = chartView.getTransformer(forAxis: .left).pixelForValues(x: xValue, y: 0)
            let adjustedX = pixelPosition.x - chartView.viewPortHandler.contentLeft
            positions.append(adjustedX)
            labels.append(formattedDate(Int64(entry.x)))
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
        chartView.scaleXEnabled = true
        chartView.scaleYEnabled = false
        chartView.dragEnabled = true
        chartView.pinchZoomEnabled = true
        chartView.doubleTapToZoomEnabled = false
        
        // Enable highlighting on touch
        chartView.highlightPerDragEnabled = true
        chartView.highlightPerTapEnabled = true
        chartView.dragXEnabled = true
        chartView.dragYEnabled = false
        
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
        leftAxis.drawGridLinesEnabled = false
        leftAxis.labelTextColor = UIColor(red: 0/255, green: 71/255, blue: 121/255, alpha: 1)
        leftAxis.gridColor = UIColor.lightGray.withAlphaComponent(0.5)
        
        // Điều chỉnh để các nhãn thẳng hàng
        leftAxis.axisMinLabels = 5 // Số lượng nhãn hiển thị
        leftAxis.forceLabelsEnabled = true
        leftAxis.granularity = 0.2
        leftAxis.spaceTop = 0.1 // Thêm 10% khoảng trống phía trên
        leftAxis.spaceBottom = 0.05 // Thêm 5% khoảng trống phía dưới
//        leftAxis.a = true

        // Configure Right Y-Axis (Index)
        let rightAxis = chartView.rightAxis
        rightAxis.drawAxisLineEnabled = false
        rightAxis.labelTextColor = UIColor(red: 196/255, green: 26/255, blue: 22/255, alpha: 1)
        rightAxis.drawGridLinesEnabled = true
        rightAxis.axisMinLabels = 5 // Đảm bảo cùng số lượng nhãn
        rightAxis.forceLabelsEnabled = true
        rightAxis.spaceTop = 0.1 // Thêm 10% khoảng trống phía trên
        rightAxis.spaceBottom = 0.05 // Thêm 5% khoảng trống phía dưới
//        rightAxis.avoidFirstLastClippingEnabled = true

        chartView.setScaleMinima(0.9, scaleY: 1.0)

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
        peDataSet.mode = .cubicBezier
        peDataSet.highlightEnabled = true
        peDataSet.setColor(peDataSetColor)
        peDataSet.lineWidth = 0.5
//        peDataSet.fillAlpha = 65/255
//        peDataSet.fillColor = UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1)
        peDataSet.highlightColor = .black.withAlphaComponent(0.8)
        peDataSet.drawHorizontalHighlightIndicatorEnabled = false
        peDataSet.drawVerticalHighlightIndicatorEnabled = true
        peDataSet.highlightLineWidth = 1
        
        // Configure Index data set (red line)
        let indexDataSet = LineChartDataSet(entries: indexDataEntry, label: "Index")
        indexDataSet.axisDependency = .right
        indexDataSet.setColor(indexDataSetColor)
        indexDataSet.lineWidth = 0.5
//        indexDataSet.fillAlpha = 65/255
//        indexDataSet.fillColor = UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1)
        indexDataSet.highlightColor = .black.withAlphaComponent(0.8)
        indexDataSet.drawCirclesEnabled = false
        indexDataSet.drawValuesEnabled = false
        indexDataSet.mode = .cubicBezier
        indexDataSet.highlightEnabled = true
        indexDataSet.drawHorizontalHighlightIndicatorEnabled = false
        indexDataSet.drawVerticalHighlightIndicatorEnabled = true
        indexDataSet.highlightLineWidth = 1
        let data: LineChartData = [peDataSet, indexDataSet]
        chartView.data = data
        chartView.data!.isHighlightEnabled = true
    }

    func filterDataForPeriod(days: Int) {
        let currentDate = Date()
        let calendar = Calendar.current
        let pastDate = calendar.date(byAdding: .day, value: -days, to: currentDate)!
        let pastTimestamp = Int(pastDate.timeIntervalSince1970)
        
        let filteredData = self.data.filter { $0.timeStamp >= pastTimestamp }
        updateChart(with: filteredData)
        
        // update overlay
        controlView.updateOverlay(filteredData)
    }

    func filterDataYearToDate() {
        let currentDate = Date()
        let calendar = Calendar.current
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: currentDate))!
        let startTimestamp = Int(startOfYear.timeIntervalSince1970)
        
        let filteredData = self.data.filter { $0.timeStamp >= startTimestamp }
        updateChart(with: filteredData)
        
        // update overlay
        controlView.updateOverlay(filteredData)
    }

    func useAllData() {
        updateChart(with: self.data)
        
        // update overlay
        controlView.updateOverlay(data)
    }

    func updateChart(with filteredData: [ChartPointModel]) {
        guard !filteredData.isEmpty else { return }
        // remove highlight point when update chartview
        handleEndHighlight()
        
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
        
        // Tính toán giá trị min/max cho cả hai trục
        if let minPe = filteredData.min(by: { $0.pe < $1.pe })?.pe,
           let maxPe = filteredData.max(by: { $0.pe < $1.pe })?.pe,
           let minIndex = filteredData.min(by: { $0.index < $1.index })?.index,
           let maxIndex = filteredData.max(by: { $0.index < $1.index })?.index {
            
            // Thêm padding để đồ thị có khoảng trống ở trên và dưới
            let peRange = maxPe - minPe
            let indexRange = maxIndex - minIndex
            
            let minPeWithPadding = minPe - (peRange * 0.05)
            let maxPeWithPadding = maxPe + (peRange * 0.1)
            
            let minIndexWithPadding = minIndex - (indexRange * 0.05)
            let maxIndexWithPadding = maxIndex + (indexRange * 0.1)
            
            // Cập nhật phạm vi trục Y
            chartView.leftAxis.axisMinimum = Double(minPeWithPadding)
            chartView.leftAxis.axisMaximum = Double(maxPeWithPadding)
            
            chartView.rightAxis.axisMinimum = Double(minIndexWithPadding)
            chartView.rightAxis.axisMaximum = Double(maxIndexWithPadding)
        }
        
        // Cập nhật phạm vi trục X
        if let minX = filteredData.min(by: { $0.timeStamp < $1.timeStamp })?.timeStamp,
           let maxX = filteredData.max(by: { $0.timeStamp < $1.timeStamp })?.timeStamp {
            chartView.xAxis.axisMinimum = Double(minX)
            chartView.xAxis.axisMaximum = Double(maxX)
        }
        
        // Cập nhật dữ liệu biểu đồ và reset view
        chartView.notifyDataSetChanged()
        chartView.fitScreen()
        
        // Cập nhật tick marks
        updateTickMarksAfterChangeData()
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
        markerInfoView.isHidden = false
    }
    
    func setHighlightPoint(_ point: CGPoint, dataSetIndex: Int) {
        let pointLayer = CALayer()
        pointLayer.frame = .init(x: point.x - highlightPointExpand / 2, y: point.y - highlightPointExpand / 2, width: highlightPointExpand, height: highlightPointExpand)
        pointLayer.cornerRadius = highlightPointExpand / 2
        pointLayer.backgroundColor = (dataSetIndex == 0 ? peDataSetColor : indexDataSetColor).withAlphaComponent(0.3).cgColor
        pointLayer.name = "highlight_point_\(dataSetIndex)"
        
        let centerLayer = CALayer()
        let x = (highlightPointExpand - highlightPointWidth) / 2
        centerLayer.frame = .init(x: x, y: x, width: highlightPointWidth, height: highlightPointWidth)
        centerLayer.cornerRadius = highlightPointWidth / 2
        centerLayer.backgroundColor = (dataSetIndex == 0 ? peDataSetColor : indexDataSetColor).cgColor
        centerLayer.borderColor = UIColor.white.cgColor
        centerLayer.borderWidth = 1
        
        pointLayer.addSublayer(centerLayer)
        
        removeHighlightPoint(for: dataSetIndex)
        layer.addSublayer(pointLayer)
    }
    
    func removeHighlightPoint(for dataSetIndex: Int) {
        layer.sublayers?.forEach { sub in
            if sub.name == "highlight_point_\(dataSetIndex)" {
                sub.removeFromSuperlayer()
            }
        }
    }
    
    func handleEndHighlight() {
        markerInfoView.isHidden = true
        removeHighlightPoint(for: 0)
        removeHighlightPoint(for: 1)
        chartView.highlightValue(nil)
        chartView.data?.dataSets.forEach{
            if let dataSet = $0 as? LineChartDataSet {
                dataSet.lineWidth = 1
            }
        }
    }
}

// MARK: - Chart Delegates
extension ChartView: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        updateInfoLabels(with: entry, highlight: highlight)
        guard let peDataSet = chartView.data?.dataSets[0] as? LineChartDataSet,
              let indexDataSet = chartView.data?.dataSets[1] as? LineChartDataSet else {
            return
        }
        
        peDataSet.lineWidth = highlight.dataSetIndex == 0 ? 2 : 1
        indexDataSet.lineWidth = highlight.dataSetIndex == 1 ? 2 : 1
        
        //draw first point
        let firstPosition = self.chartView.getTransformer(forAxis: highlight.axis).pixelForValues(x: entry.x, y: entry.y)
        setHighlightPoint(firstPosition, dataSetIndex: highlight.dataSetIndex)
        
        // draw second point
        let secondDataSet = highlight.dataSetIndex == 0 ? indexDataSet : peDataSet // index = 0 is pe -> second is index
        if let secondEntry = secondDataSet.entryForXValue(entry.x, closestToY: 1) {
            let secondPosition = self.chartView.getTransformer(forAxis: highlight.axis == .left ? .right : .left).pixelForValues(x: secondEntry.x, y: secondEntry.y)

            setHighlightPoint(secondPosition, dataSetIndex: highlight.dataSetIndex == 0 ? 1 : 0)
        }
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        handleEndHighlight()
    }
    
    func chartScaled(_ chartView: ChartViewBase, scaleX: CGFloat, scaleY: CGFloat) {
        handleEndHighlight()
        // Chỉ xử lý khi scale theo trục X
        print("chartScaled Current scaleX: \(self.chartView.scaleX)")
//        chartView.viewPortHandler.setZoom(scaleX: 1.0, scaleY: 1.0)

    }
    
    func chartViewDidEndPanning(_ chartView: ChartViewBase) {
        // Lấy giá trị scaleX từ viewPortHandler
        handleEndHighlight()
    }
    
    func chartTranslated(_ chartView: ChartViewBase, dX: CGFloat, dY: CGFloat) {
        let scaleX = chartView.viewPortHandler.scaleX
        print("chartTranslated scaleX: \(scaleX)")
    }
    
    func chartView(_ chartView: ChartViewBase, animatorDidStop animator: Animator) {
        print("animatorDidStop")
    }
}

// MARK: - Control View Delegate
extension ChartView: ControlViewDelegate {
    func controlView(_ controlView: ControlView, didUpdateRange range: (start: Double, end: Double)) {
        // Set flag to prevent recursive updates
        isUpdatingFromControlView = true
        
        // Filter data based on selected range
        let filteredData = self.data.filter {
            Double($0.timeStamp) >= range.start && Double($0.timeStamp) <= range.end
        }
        
        // Update chart with filtered data
        updateChart(with: filteredData)
        
        // Reset flag
        isUpdatingFromControlView = false
        
        // Update the info view with the first visible point
        if let firstEntry = chartView.data?.dataSets[0].entryForIndex(0) {
            let highlightObj = Highlight(x: firstEntry.x, y: firstEntry.y, dataSetIndex: 0)
            updateInfoLabels(with: firstEntry, highlight: highlightObj)
        }
    }
}
