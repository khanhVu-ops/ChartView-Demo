//
//  Formatters.swift
//  ChartDemo
//
//  Created by Khanh Vu on 2/4/25.
//

import UIKit


func formatTimestamps(_ timestamps: [Int64]) -> [String] {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US")
    
    // Tạo Date objects từ timestamps
    let dates = timestamps.map { Date(timeIntervalSince1970: TimeInterval($0)) }
    
    // Tạo dictionary để kiểm tra các năm và tháng trùng lặp
    var yearCounts: [Int: Int] = [:]
    var yearMonthCounts: [String: Int] = [:]
    
    // Đếm số lần xuất hiện của mỗi năm và cặp năm-tháng
    for date in dates {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        
        yearCounts[year, default: 0] += 1
        let yearMonthKey = "\(year)-\(month)"
        yearMonthCounts[yearMonthKey, default: 0] += 1
    }
    
    // Format mỗi timestamp theo quy tắc
    return zip(dates, timestamps).map { (date, _) in
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let yearMonthKey = "\(year)-\(month)"
        
        // Trường hợp 1: Nếu năm là duy nhất trong mảng
        if yearCounts[year] == 1 {
            return "\(year)"
        }
        // Trường hợp 2: Nếu năm trùng lặp nhưng tháng là duy nhất trong năm đó
        else if yearMonthCounts[yearMonthKey] == 1 {
            dateFormatter.dateFormat = "MMM''yy" // Format kiểu "Jun'24"
            return dateFormatter.string(from: date)
        }
        // Trường hợp 3: Nếu cả năm và tháng đều trùng lặp
        else {
            dateFormatter.dateFormat = "dd.MMM" // Format kiểu "17.Feb"
            return dateFormatter.string(from: date)
        }
    }
}

func getYearFromTimestamp(_ timestamp: Int64) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
    let calendar = Calendar.current
    let year = calendar.component(.year, from: date)
    return "\(year)"
}
