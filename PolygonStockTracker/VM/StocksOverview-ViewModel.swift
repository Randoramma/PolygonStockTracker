//
//  StocksOverviewViewModel.swift
//  PolygonStockTracker
//
//  Created by Randy McLain on 3/2/24.
//

import Foundation
import Combine

extension StocksOverview {
    class ViewModel: ObservableObject {
        
        // MARK: - Properties
        
        let networkService: NetworkServicable
        let persistenceService: Storable
        private let jsonDecoder: JSONDecoder = JSONDecoder()
        private var updateStockService: BasicStockOverviewService
        
        @Published var stocks: [BasicStockValue] = []
        @Published var stocksLoading: Bool = false
        // TODO: -  make private setters
        private var cancellables = Set<AnyCancellable>()
        init(networkService: NetworkServicable = NetworkService(),
             persistence: Storable,
             stockService: BasicStockOverviewService) {
            self.networkService = networkService
            self.updateStockService = stockService
            self.persistenceService = persistence
            subscribeToPublisher()
        }
        
        private func subscribeToPublisher() {
            updateStockService.stockValuesPublisher
                .sink { [weak self] (newStockValues) in
                    guard let self = self else { return }
                    self.stocksLoading = true
                    DispatchQueue.main.async {
                        self.stocksLoading = false
                        self.persistenceService.addUpdatedStocksToStore(newStockValues)
                        self.stocks = newStockValues
                        self.stocksLoading = false
                    }
                }
                .store(in: &cancellables)
        }
        
        func fetchUpdatedStocks() async {
            DispatchQueue.main.async {
                self.stocksLoading = true
            }
            await self.updateStockService.fetchCurrentInfoForStocks(symbols: stocks)
        }
        
        func updateLocalStocks() {
            self.stocksLoading = true
            let stocks = persistenceService.getStoredStockValues()
            DispatchQueue.main.async {
                self.stocks = stocks
                self.stocksLoading = false
            }
        }

        deinit {
            cancellables.removeAll()
        }
    }
}
