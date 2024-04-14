//
//  Stock.swift
//  PolygonStockTracker
//
//  Created by Randy McLain on 3/1/24.
//

import Foundation

struct BasicStockValue: Hashable, Codable, Identifiable {
    
    // MARK: - Properties
    
    let id: UUID = UUID()
    let ticker: String
    let daily: Double
    let dailyChange: Double
    let date: Int
    var marketCap: Double?
    
    // Initialize with a ticker symbol; generate UUID based on ticker ..  but cannot do this with decodable because
    // cannot have ticker and id evaluate to the same coding key.
    init(ticker: String, daily: Double, dailyChange: Double, date: Int, marketCap: Double? = nil) {
        self.ticker = ticker
        self.daily = daily
        self.dailyChange = dailyChange
        self.date = date
        self.marketCap = marketCap
    }
    
    enum CodingKeys: CodingKey {
        case id, ticker, daily, dailyChange, date
    }
    
    
    static func == (lhs: BasicStockValue, rhs: BasicStockValue) -> Bool {
            return lhs.ticker == rhs.ticker
    }
        
    func hash(into hasher: inout Hasher) {
        hasher.combine(ticker) // Use ticker for uniqueness
    }
}

/*
 {
   "ticker": "AAPL", String The exchange symbol that this item is traded under.
   "queryCount": 818, Int The number of aggregates (minute or day) used to generate the response.
   "resultsCount": 32, Int The total number of results for this request.
   "adjusted": false, Bool Whether or not this response was adjusted for splits.
   "results": [
     {
       "v": 33474, = v The trading volume of the symbol in the given time period.
       "vw": 129.7972, = The volume weighted average price.
       "o": 129.78, = The open price for the symbol in the given time period.
       "c": 129.85, = The close price for the symbol in the given time period.
       "h": 129.85, = The highest price for the symbol in the given time period.
       "l": 129.76, = The lowest price for the symbol in the given time period.
       "t": 1673310600000, = The Unix Msec timestamp for the start of the aggregate window.
       "n": 580 = The number of transactions in the aggregate window.
     }
 */

struct Stock: Codable {
    
    let ticker: String
    let results: [Results]?
    
    enum CodingKeys: String, CodingKey {
        case ticker, results
    }
    
    func latestResult() -> Results? {
        return results?.first
    }
}
        
struct Results: Codable, Identifiable {
    var id: Int { timestamp }
    let volume: Int
    let closePrice: Double
    let high: Double
    let low: Double
    let timestamp: Int
    
    enum CodingKeys: String, CodingKey {
        case volume = "v"
        case closePrice = "c"
        case high = "h"
        case low = "l"
        case timestamp = "t"
    }
}
