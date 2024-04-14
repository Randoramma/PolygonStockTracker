//
//  StockDetail.swift
//  PolygonStockTracker
//
//  Created by Randy McLain on 3/5/24.
//

import Foundation

struct StockDetail: Decodable {
    
    let requestID: String
    let status: String
    let results: StockDetailResults
    
    enum CodingKeys: String, CodingKey {
        case requestID = "request_id"
        case status, results
    }
}

struct StockDetailResults: Decodable {
    let marketCap: Double
    
    enum CodingKeys: String, CodingKey {
        case marketCap = "market_cap"
    }
}
