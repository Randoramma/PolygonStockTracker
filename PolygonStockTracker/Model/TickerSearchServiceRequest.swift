//
//  TickerSearchRequest.swift
//  PolygonStockTracker
//
//  Created by Randy McLain on 3/3/24.
//

import Foundation

struct TickerSearchServiceRequest {

    // MARK: - Properties
    
    private let baseUrl = URL(string: "https://api.polygon.io/v3/reference/tickers")!
    private let apiKey: String
    private let searchTerm: String
    
    // MARK: - Initialization
    
    init(searchTerm: String, apiKey: String) {
        self.searchTerm = searchTerm
        self.apiKey = apiKey
    }
    
    // MARK: - Public API
    
    var url: URL {
        guard var components = URLComponents(url: baseUrl, resolvingAgainstBaseURL: false) else {
            fatalError("Unable to Create URL Components for Ticker Search Service Request")
        }
        
        components.queryItems = [
            URLQueryItem(name: "market", value: "stocks"),
            URLQueryItem(name: "search", value: searchTerm),
            URLQueryItem(name: "active", value: "true"),
            URLQueryItem(name: "sort", value: "ticker"),
            URLQueryItem(name: "order", value: "asc"),
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "apiKey", value: apiKey)
        ]
        
        guard let url = components.url else {
            fatalError("Unable to Create URL for Ticker Search Service Request")
        }
        
        return url
    }
}
