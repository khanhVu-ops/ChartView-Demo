////
////  Untitled.swift
////  ChartDemo
////
////  Created by Khanh Vu on 31/3/25.
////
//
//// BalloonMarker.swift
//import Foundation
//import DGCharts
//import UIKit
//
//public class BalloonMarker: MarkerImage {
//    private var color: UIColor
//    private var arrowSize = CGSize(width: 15, height: 11)
//    private var font: UIFont
//    private var textColor: UIColor
//    private var insets: UIEdgeInsets
//    private var minimumSize = CGSize()
//    
//    private var labelText: String?
//    private var attributes = [NSAttributedString.Key : Any]()
//    
//    public init(color: UIColor, font: UIFont, textColor: UIColor, insets: UIEdgeInsets) {
//        self.color = color
//        self.font = font
//        self.textColor = textColor
//        self.insets = insets
//        
//        attributes[.font] = self.font
//        attributes[.foregroundColor] = self.textColor
//        
//        super.init()
//    }
//    
//    public override func offsetForDrawing(atPoint point: CGPoint) -> CGPoint {
//        var offset = self.offset
//        let size = self.size
//        
//        if point.x + offset.x < 0 {
//            offset.x = -point.x
//        }
//        else if point.x + size.width + offset.x > self.chartView?.bounds.width ?? 0 {
//            offset.x = (self.chartView?.bounds.width ?? 0) - point.x - size.width
//        }
//        
//        if point.y + offset.y < 0 {
//            offset.y = -point.y
//        }
//        else if point.y + size.height + offset.y > self.chartView?.bounds.height ?? 0 {
//            offset.y = (self.chartView?.bounds.height ?? 0) - point.y - size.height
//        }
//        
//        return offset
//    }
//    
//    public override func draw(context: CGContext, point: CGPoint) {
//        guard let labelText = labelText else { return }
//        
//        let offset = self.offsetForDrawing(atPoint: point)
//        let size = self.size
//        
//        let rect = CGRect(
//            origin: CGPoint(
//                x: point.x + offset.x,
//                y: point.y + offset.y),
//            size: size)
//        
//        context.saveGState()
//        
//        context.setFillColor(color.cgColor)
//        context.beginPath()
//        context.move(to: CGPoint(x: rect.minX, y: rect.minY))
//        context.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
//        context.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - arrowSize.height))
//        context.addLine(to: CGPoint(x: rect.midX + arrowSize.width / 2, y: rect.maxY - arrowSize.height))
//        context.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
//        context.addLine(to: CGPoint(x: rect.midX - arrowSize.width / 2, y: rect.maxY - arrowSize.height))
//        context.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - arrowSize.height))
//        context.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
//        context.fillPath()
//        
//        rect.origin.y += self.insets.top
//        rect.size.height -= self.insets.top + self.insets.bottom
//        
//        UIGraphicsPushContext(context)
//        
//        labelText.draw(in: rect, withAttributes: attributes)
//        
//        UIGraphicsPopContext()
//        
//        context.restoreGState()
//    }
//    
//    public override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
//        let yValue = entry.y
//        let xValue = formattedDate(Int64(entry.x))
//        labelText = "\(xValue)\nValue: \(String(format: "%.2f", yValue))"
//    }
//    
//    private func formattedDate(_ timestamp: Int64) -> String {
//        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MMM''yy"
//        formatter.locale = Locale(identifier: "en_US")
//        return formatter.string(from: date).lowercased().capitalized
//    }
//    
//    public override var size: CGSize {
//        guard let labelText = labelText else { return minimumSize }
//        
//        let size = labelText.size(withAttributes: attributes)
//        let width = size.width + insets.left + insets.right
//        let height = size.height + insets.top + insets.bottom + arrowSize.height
//        
//        var result = CGSize(width: width, height: height)
//        result.width = max(minimumSize.width, result.width)
//        result.height = max(minimumSize.height, result.height)
//        
//        return result
//    }
//    
//    open var minimumSize: CGSize {
//        get { return _minimumSize }
//        set { _minimumSize = newValue }
//    }
//    private var _minimumSize = CGSize()
//}
