//
//  ListOfStockView-ViewModel.swift
//  PolygonStockTracker
//
//  Created by Randy McLain on 3/4/24.
//

import Foundation

extension ListOfStocksView {
    class ViewModel: ObservableObject {
        
        let persistenceService: Storable
        @Published var stocks: [BasicStockValue] = []
        init(persistence: Storable = PersistenceService()) {
            self.persistenceService = persistence
            self.setupStocks()
        }
        
        func setupStocks() {
            self.persistenceService.getStoredStockValues { [weak self] stocks in
                guard let self = self else { return } // dont forget 'in' after capture list
                DispatchQueue.main.async {
                    self.stocks = stocks
                   // self.persistenceService.replaceStocksInStoreWith(stocks)
                }
            }
        }

        func addStock(stock: BasicStockValue) {
            self.persistenceService.getStoredStockValues { [weak self] stocks in
                guard let self = self else { return } // dont forget 'in' after capture list
                DispatchQueue.main.async {
                    self.stocks = stocks
                    self.stocks.append(stock)
                    self.persistenceService.addUpdatedStocksToStore(self.stocks)
                }
            }
        }
        
        func removeStockAt(offsets: IndexSet) {
            let index = offsets.startIndex
            let stockToRemove: [BasicStockValue] = stocks.enumerated()
                .filter { offsets.contains($0.offset) }
                .map { $0.element }
            
            self.persistenceService.getStoredStockValues { [weak self] stocks in
                guard let self = self else { return } // dont forget 'in' after capture list
                DispatchQueue.main.async {
                    self.stocks = stocks
                    print("Before:  \(self.stocks)")
                    let tickers = stockToRemove.map { $0.ticker }
                    self.stocks.removeAll { stockSymbol in
                        tickers.contains(stockSymbol.ticker)
                    }
                    print("AFter:  \(self.stocks)")
                    self.persistenceService.replaceStocksInStoreWith(self.stocks)
                }
            }
        }
    }
}
