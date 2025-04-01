//
//  ChartModel.swift
//  ChartDemo
//
//  Created by Khanh Vu on 31/3/25.
//

import UIKit

struct ChartModel: Decodable {
    let data: ChartData
    let message: String
    let success: Bool

    enum CodingKeys: String, CodingKey {
        case data = "Data"
        case message = "Message"
        case success = "Success"
    }
}

// MARK: - DataClass
struct ChartData: Decodable {
    let nowDataFinance, pastDataFinance: DataFinance
    let dataChart: [ChartPointModel]

    enum CodingKeys: String, CodingKey {
        case nowDataFinance = "NowDataFinance"
        case pastDataFinance = "PastDataFinance"
        case dataChart = "DataChart"
    }
}

// MARK: - DataChart
struct ChartPointModel: Decodable {
    let pe, index: Double
    let lnst: Int
    let time: String
    let timeStamp: Int64

    enum CodingKeys: String, CodingKey {
        case pe = "Pe"
        case index = "Index"
        case lnst = "LNST"
        case time = "Time"
        case timeStamp = "TimeStamp"
    }
}

// MARK: - DataFinance
struct DataFinance: Decodable {
    let pb, pe, roa, roe: Double
    let maketCap: Int

    enum CodingKeys: String, CodingKey {
        case pb = "PB"
        case pe = "PE"
        case roa = "ROA"
        case roe = "ROE"
        case maketCap = "MaketCap"
    }
}

extension ChartModel {
    static func loadFromFile(named filename: String = "chart") -> ChartModel? {
        // Get the path to the JSON file in the app bundle
        guard let path = Bundle.main.path(forResource: filename, ofType: "json") else {
            print("Could not find file: \(filename).json")
            return nil
        }
        
        do {
            // Read the data from the file
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            
            // Create a JSON decoder
            let decoder = JSONDecoder()
            
            // Decode the data into a ChartModel
            let chartModel = try decoder.decode(ChartModel.self, from: data)
            return chartModel
        } catch {
            print("Error loading or parsing JSON file: \(error)")
            return nil
        }
    }
}


func formattedDate(_ timeStamp: Int64) -> String {
    // Convert timestamp to Date object
    // Note: Adjust the multiplier if your timestamp is in seconds (×1) or milliseconds (×0.001)
    let date = Date(timeIntervalSince1970: TimeInterval(timeStamp))
    
    // Create DateFormatter
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM''yy"
    formatter.locale = Locale(identifier: "en_US")
    
    // Return formatted string (e.g., "May'21")
    return formatter.string(from: date).lowercased().capitalized
}

func getStrideData(_ data: [ChartPointModel], step: Int = 1) -> [ChartPointModel] {
    var sampledData: [ChartPointModel] = []
    
    for index in stride(from: 0, to: data.count, by: step) {
        sampledData.append(data[index])
    }
    
    return sampledData
}

