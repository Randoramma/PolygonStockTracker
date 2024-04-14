//
//  StockSummary.swift
//  PolygonStockTracker
//
//  Created by Randy McLain on 3/6/24.
//

import Foundation

struct StockSummary: Identifiable {
    let date: Date
    let price: Double
    let id: Int
  //  let dateFormatter: DateFormatter
    
    init (timestamp: Int, sales: Double) {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp/1000)) // convert from milliseconds.
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        if let year = components.year, let month = components.month, let day = components.day {
            self.date = StockSummary.date(year: year, month: month, day: day)
        } else {
            // log this error!
            self.date = date
        }
        
     //   self.dateFormatter = formatter
        self.price = sales
        self.id = timestamp
    }
    
    static func date(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
}
