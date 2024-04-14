//
//  HistoricalAggregateRequest.swift
//  PolygonStockTracker
//
//  Created by Randy McLain on 3/4/24.
//

import Foundation

/*
 https://api.polygon.io/v2/aggs/ticker/AAPL/range/1/day/2023-12-05/2024-03-01?adjusted=true&sort=asc&limit=120&apiKey=
 */

struct HistoricalAggregateRequest {
    // MARK: - Properties
    
    private let baseUrl = URL(string: Constants.tickerAggregateV2API)!
    private let apiKey: String
    private let ticker: String
    private let fromDate: String
    private let toDate: String
    
    // MARK: - Initialization
    
    init(ticker: String, fromDate: String, toDate: String, apiKey: String) {
        self.ticker = ticker
        self.fromDate = fromDate
        self.toDate = toDate
        self.apiKey = apiKey
    }
    
    var url: URL {
        let fullPath = "\(baseUrl.absoluteString)\(ticker)/range/1/day/\(fromDate)/\(toDate)"
        
        guard var components = URLComponents(string: fullPath) else {
            fatalError("Unable to Create URL Components for Stock Data Service Request")
        }
        
        components.queryItems = [
            URLQueryItem(name: "adjusted", value: "true"),
            URLQueryItem(name: "sort", value: "desc"),
            URLQueryItem(name: "limit", value: "120"),
            URLQueryItem(name: "apiKey", value: apiKey)
        ]
        
        guard let url = components.url else {
            fatalError("Unable to Create URL for Stock Data Service Request")
        }
        
        return url
    }
}
