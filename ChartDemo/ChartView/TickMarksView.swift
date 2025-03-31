//
//  TickMarksView.swift
//  ChartDemo
//
//  Created by Khanh Vu on 31/3/25.
//

import UIKit

class TickMarksView: UIView {
    var tickPositions: [CGFloat] = [] // Vị trí tick marks trên X-axis
    var tickLabels: [String] = [] // Text hiển thị bên dưới tick marks
    var tickColor: UIColor = .black
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        for (index, tickX) in tickPositions.enumerated() {
            // 🎯 Vẽ Tick Mark
            context.setStrokeColor(tickColor.cgColor) // Màu tick marks
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: tickX, y: 0))
            context.addLine(to: CGPoint(x: tickX, y: 9))
            context.strokePath()
            
            // 🎯 Vẽ Text bên dưới Tick Mark
            let text = tickLabels[index]
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.black,
            ]
            let textSize = text.size(withAttributes: attributes)
            let textX = tickX - textSize.width / 2
            let textY: CGFloat = 9  // Khoảng cách dưới tick mark
            
            text.draw(at: CGPoint(x: textX, y: textY), withAttributes: attributes)
        }
    }
}
