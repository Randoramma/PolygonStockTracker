//
//  StockDetailRequest.swift
//  PolygonStockTracker
//
//  Created by Randy McLain on 3/5/24.
//

import Foundation

// https://api.polygon.io/v3/reference/tickers/AAPL?date=2024-03-05&apiKey=


struct StockDetailRequest {
    // MARK: - Properties
    
    private let baseUrl = URL(string: Constants.tickersReferenceV3API)!
    private let ticker: String
    private let apiKey: String
    private let date: String
    
    // MARK: - Initialization
    
    init(date: String, apiKey: String, ticker: String) {
        self.date = date
        self.apiKey = apiKey
        self.ticker = ticker
    }
    
    // MARK: - Public API
    
    var url: URL {
        let fullPath = "\(baseUrl.absoluteString)\(ticker)"
        
        guard var components = URLComponents(string: fullPath) else {
            fatalError("Unable to Create URL Components for Stock Data Service Request")
        }
        
        components.queryItems = [
            URLQueryItem(name: "date", value: date),
            URLQueryItem(name: "apiKey", value: apiKey)
        ]
        
        guard let url = components.url else {
            fatalError("Unable to Create URL for Ticker Search Service Request")
        }
        return url
    }
}
