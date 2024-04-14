//
//  PersistenceService.swift
//  PolygonStockTracker
//
//  Created by Randy McLain on 3/4/24.
//

import Foundation

// Define a protocol for storage to ensure modularity and ease of swapping storage solutions
protocol Storable {
    func replaceStocksInStoreWith(_ stockValues: [BasicStockValue])
    func addUpdatedStocksToStore(_ newStockValues:  [BasicStockValue])
    func getStoredStockValues() -> [BasicStockValue]
}

// UserDefaults storage class that conforms to the Storage protocol
class PersistenceService: Storable {
    
    private let defaults: UserDefaults
    private let encoder: JSONEncoder = JSONEncoder()
    private let decoder: JSONDecoder = JSONDecoder()
    
    init(defaults: UserDefaults = UserDefaults.standard) {
        self.defaults = defaults
    }
    
    func replaceStocksInStoreWith(_ stockValues: [BasicStockValue]) {
        if let encoded = try? encoder.encode(stockValues) {
            defaults.set(encoded, forKey: Constants.storedStockValuesKey)
        }
    }
    
    func addUpdatedStocksToStore(_ newStockValues:  [BasicStockValue]) {
        
        let stocks = getStoredStockValues()
        let updatedStockArray: [BasicStockValue] = self.updateStocksArrayWith(newStockValues, for: stocks)
        
        if let encoded = try? encoder.encode(updatedStockArray) {
            defaults.set(encoded, forKey: Constants.storedStockValuesKey)
        }
    }
    
    func getStoredStockValues() -> [BasicStockValue] {
        if let data = defaults.value(forKey: Constants.storedStockValuesKey) as? Data {
            if let array = try? decoder.decode([BasicStockValue].self, from: data) {
                return array
            }
        }
        return []
    }
    
    private func updateStocksArrayWith(_ stockObjects: [BasicStockValue],
                               for array: [BasicStockValue]) -> [BasicStockValue] {
            let combinedArray = array + stockObjects
            let updatedStocks = Dictionary(grouping: combinedArray, by: { $0.ticker })
                .mapValues { stockGroup -> BasicStockValue? in
                    stockGroup.max(by: { $0.date < $1.date })
                }
                .compactMap { $0.value }
            return updatedStocks
    }
}
