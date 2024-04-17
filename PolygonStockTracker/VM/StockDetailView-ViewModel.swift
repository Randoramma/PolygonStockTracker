//
//  StockDetailView-ViewModel.swift
//  PolygonStockTracker
//
//  Created by Randy McLain on 3/4/24.
//

import Foundation
import Combine

extension StockDetailView {
    class ViewModel: ObservableObject {
        
        // MARK: - Properties
        
        private let networkService: NetworkServicable
        private let persistenceService: Storable
        private let jsonDecoder: JSONDecoder = JSONDecoder()
        private var stockDataService: HistoricalStockDataService
        private let dateFormatter: DateFormatter = DateFormatter()
        @Published var stock: Stock?
        @Published var basicStockValue: BasicStockValue
        @Published var seriesData: [StockSummary] = []
        // TODO: -  make private setters
        private var cancellables = Set<AnyCancellable>()
        init(networkService: NetworkServicable = NetworkService(),
                persistenceService: Storable,
                stockService: HistoricalStockDataService,
             basicStockValue: BasicStockValue) {
            self.networkService = networkService
            self.stockDataService = stockService
            self.persistenceService = persistenceService
            self.basicStockValue = basicStockValue
            subscribeToPublisher()
        }
        
        private func subscribeToPublisher() {
            stockDataService.stockValuesPublisher
                .sink { [weak self] (newStockValue) in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.seriesData = []
                    }
                    if let results = newStockValue.results {
                        for item in results {
                            let seriesDatum = StockSummary(timestamp: item.timestamp,
                                                           sales: item.closePrice)
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else { return }
                                self.seriesData.append(seriesDatum)
                            }
                        }
                    }
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.stock = newStockValue
                    }
                }
                .store(in: &cancellables)
            
            stockDataService.basicStockValuesPublisher
                .sink {  [weak self] (newBasicStockValue) in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.persistenceService.addUpdatedStocksToStore([])
                        self.basicStockValue = newBasicStockValue
                    }
                }
                .store(in: &cancellables)
        }
        
        func fetchHistoricalStockData(_ stock: BasicStockValue) async {
            await self.stockDataService.fetchHistoricalInfoForStocks(symbol: stock)
            // TODO: -  should investigate a way to limit this?
            await self.stockDataService.fetchMarketCapInfoForStock(symbol: stock)
        }
        
        deinit {
            cancellables.removeAll()
        }
    }
}
