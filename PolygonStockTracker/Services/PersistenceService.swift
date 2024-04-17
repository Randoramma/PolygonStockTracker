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
    func getStoredStockValues(completion: @escaping ([BasicStockValue]) -> Void)
}

extension Storable {
    func awaitStoredStockValues() async -> [BasicStockValue] {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                guard let data = UserDefaults.standard.value(forKey: Constants.storedStockValuesKey) as? Data else {
                    continuation.resume(returning: [])
                    return
                }

                do {
                    let array = try JSONDecoder().decode([BasicStockValue].self, from: data)
                    continuation.resume(returning: array)
                } catch {
                    continuation.resume(returning: [])
                }
            }
        }
    }
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
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return } // dont forget 'in' after capture list
                self.defaults.set(encoded, forKey: Constants.storedStockValuesKey)
            }
        }
    }
    
    func addUpdatedStocksToStore(_ newStockValues:  [BasicStockValue]) {
        
        self.getStoredStockValues { [weak self] stocks in
            guard let self = self else { return }
            let updatedStockArray: [BasicStockValue] = self.updateStocksArrayWith(newStockValues, for: stocks)
            
            if let encoded = try? encoder.encode(updatedStockArray) {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.defaults.set(encoded, forKey: Constants.storedStockValuesKey)
                }
            }
        }
    }
    
    func getStoredStockValues(completion: @escaping ([BasicStockValue]) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let _ = self else {
                completion([])
                return
            }

            guard let data = UserDefaults.standard.value(forKey: Constants.storedStockValuesKey) as? Data else {
                completion([])
                return
            }

            do {
                let array = try JSONDecoder().decode([BasicStockValue].self, from: data)
                completion(array)
            } catch {
                completion([])
            }
        }
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
