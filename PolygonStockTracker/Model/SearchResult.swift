//
//  SearchResult.swift
//  PolygonStockTracker
//
//  Created by Randy McLain on 3/3/24.
//

import Foundation

struct SearchResultResponse: Decodable {
    let results: [SearchTicker]
    let status: String
    let requestId: String
    let count: Int
    let nextUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case results, status, count
        case requestId = "request_id"
        case nextUrl = "next_url"
    }
}

struct SearchTicker: Decodable, Identifiable {
    let id: UUID = UUID()
    let ticker: String
    let name: String
    let market: String
    let locale: String
    let type: String
    let active: Bool
    let currencyName: String
    let lastUpdatedUtc: String
    
    enum CodingKeys: String, CodingKey {
        case ticker, name, market, locale, type, active
        case currencyName = "currency_name"
        case lastUpdatedUtc = "last_updated_utc"
    }
}
