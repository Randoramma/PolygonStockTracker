//
//  SearchViewModel.swift
//  PolygonStockTracker
//
//  Created by Randy McLain on 3/1/24.
//

import Foundation

import UIKit
import Combine

extension SearchView {
    class ViewModel: ObservableObject {
        
        private let networkService: NetworkServicable
        private let timerService: TimeServicable
        private let jsonDecoder: JSONDecoder = JSONDecoder()
        private let persistenceService: Storable
        
        private var query: String = ""
        @Published var stockTickers: SearchResultResponse?
        private var cancellables = Set<AnyCancellable>()
        
        init(networkService: NetworkServicable,
             timerService: TimeServicable = TimerService(timerLength: 1),
             persistence: Storable) {
            self.networkService = networkService
            self.timerService = timerService
            self.persistenceService = persistence
            
            timerService.timerPublisher
                .sink { [weak self] ready in
                    guard let self = self else { return }
                    if ready {
                        Task {
                            await self.fetchTickers(query: self.query)
                        }
                    }
                }
                .store(in: &cancellables)
        }
        
        func clearTickers() {
            self.stockTickers = nil
        }
        
        func didSelectStockToAdd(ticker: String) {
            self.persistenceService.getStoredStockValues { [weak self] stocks in
                var stockArray = stocks
                guard let self = self else { return } // dont forget 'in' after capture list
                stockArray.append(BasicStockValue(ticker: ticker,
                                              daily: 0,
                                              dailyChange: 0,
                                              date: 0))
                persistenceService.addUpdatedStocksToStore(stockArray)
            }
        }
        
        // MARK: - Binding of Data to the UI
        func fetchTickers(query: String) async {
            
            precondition(ProcessInfo.processInfo.environment[Constants.apiKey] != nil)
            let apiKey = ProcessInfo.processInfo.environment[Constants.apiKey]!
            let request = TickerSearchServiceRequest(searchTerm: query, apiKey: apiKey)
            let url = request.url
            do {
                let data = try await networkService.attemptdataFor(url: url)
                let results: SearchResultResponse = try jsonDecoder.decode(SearchResultResponse.self, from: data)
                print(results)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.stockTickers = results
                }
            } catch {
                // TODO: - ERROR HANDLING: Push up a call to the view .. perhaps by updating a publisher if we get an error.. then the View can load the error into its view.
                print(error)
            }
        }
        
        // MARK: - Timer Service
        func startTimer(_ forQuery: String) {
            self.query = forQuery
            self.timerService.startTimer()
        }

        fileprivate func queryStringFrom(urlString: String, query: String) -> URL {
            let queryURL: String = urlString.replacingOccurrences(of: Constants.query, with: query)
            precondition(URL(string: queryURL) != nil, "Was unable to create url from input.. check for forbidden characters.")
            return URL(string: queryURL)!
        }
        
        deinit {
            cancellables.removeAll()
        }
    }
}
