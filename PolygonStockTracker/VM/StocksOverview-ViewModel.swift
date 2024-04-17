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
        private var networkLoading: Bool = false
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
                .receive(on: DispatchQueue.main)
                .sink { [weak self] (newStockValues) in
                    guard let self = self else { return }
                    print("new stock value in Overview = \(newStockValues)")
                    self.stocks = newStockValues
                    self.persistenceService.addUpdatedStocksToStore(newStockValues)
                    print("Stock updated \(newStockValues.count)")
                    self.updateLoadingStatusBy(newStockValues)
                }
                .store(in: &cancellables)
        }
        
        func fetchUpdatedStocks() async {
            self.networkLoading = true
            self.updateLoadingState()
            await self.updateStockService.fetchCurrentInfoForStocks(symbols: stocks)
        }
        
        func updateLocalStocks() {
            self.stocksLoading = true
            self.persistenceService.getStoredStockValues { stocks in
                DispatchQueue.main.async {
                    self.stocks = stocks
                    self.networkLoading = false
                }
            }
        }
        
        private func updateLoadingState() {
            DispatchQueue.main.async {
                self.stocksLoading = self.networkLoading
                print("the loading state is \(self.stocksLoading)")
            }
        }
        
        fileprivate func updateLoadingStatusBy(_ newStockValues: [BasicStockValue]) {
            if networkLoading {
                if (newStockValues.count > 0) {
                    self.networkLoading = false
                } else {
                    print("Stocks loading = \(stocksLoading) \n NetworkLoading = \(networkLoading), \n Stock count = \(newStockValues)")
                }
            } else {
                self.stocksLoading = false
            }
        }
        
        func closeLoadingState() {
            self.stocksLoading = false
            self.networkLoading = false
        }

        deinit {
            cancellables.removeAll()
        }
    }
}
