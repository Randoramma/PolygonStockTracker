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
            self.stocks = self.setupStocks()
        }
        
        private func setupStocks() -> [BasicStockValue] {
            return persistenceService.getStoredStockValues()
        }
        
        func updateStocksForView() {
            self.stocks = setupStocks()
            self.persistenceService.addUpdatedStocksToStore(self.stocks)
        }
        
        func addStock(stock: BasicStockValue) {
            let stocks = persistenceService.getStoredStockValues()
            self.stocks = stocks
            self.stocks.append(stock)
            self.persistenceService.addUpdatedStocksToStore(self.stocks)
        }
        
        func removeStockAt(offsets: IndexSet) {
            let stocks = persistenceService.getStoredStockValues()
            self.stocks = stocks
            print("Before:  \(self.stocks)")
            self.stocks.remove(atOffsets: offsets)
            print("AFter:  \(self.stocks)")
            self.persistenceService.replaceStocksInStoreWith(self.stocks)
        }
    }
}
