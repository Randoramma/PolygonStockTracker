//
//  Constants.swift
//  PolygonStockTracker
//
//  Created by Randy McLain on 3/2/24.
//

import Foundation

struct Constants {
    static let tickerAggregateV2API: String = "https://api.polygon.io/v2/aggs/ticker/"
    static let tickersReferenceV3API: String = "https://api.polygon.io/v3/reference/tickers/"
    static let stockTickerSearchUrl: String = "https://api.polygon.io/v3/reference/tickers?search=<query>&active=true&sort=ticker&order=asc&limit=25&apiKey=<apiAuthKey>"
    static let apiKey = "API_KEY"
    static let storedStockValuesKey: String = "StoredStockValues"
    static let ticker = "<ticker>"
    static let date = "<date>"
    static let apiAuthKey = "<apiAuthKey>"
    static let query = "<query>"
    static let dateFormat = "yyyy-MM-dd"
    static let searchStaticText = "Search For Stocks"
    static let dismiss = "Dismiss"
    static let listOfStocks = "ListOfStocks"
    static let stockdetail = "Stock Detail"
    static let marketCap = "Market Cap"
    static let volume = "Volume"
    static let price = "Price"
    static let day = "Day"
}
