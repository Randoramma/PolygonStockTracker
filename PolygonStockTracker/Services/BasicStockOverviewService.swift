//
//  UpdateStockService.swift
//  PolygonStockTracker
//
//  Created by Randy McLain on 3/4/24.
//

import Foundation
import Combine

protocol BasicStockServicable {
    func fetchCurrentInfoForStocks(symbols: [BasicStockValue]) async
    // TODO: -  add publisher to protocol when importing implementation from Menus project
    //var stockValuesPublisher: AnyPublisher<[BasicStockValue], Never>
}

class BasicStockOverviewService {
    
    private var stockValuesSubject = CurrentValueSubject<[BasicStockValue], Never>([])
    private let networkService: NetworkServicable
    private let jsonDecoder: JSONDecoder = JSONDecoder()
    
    @Published private var stockValues: [BasicStockValue] = []
    private var cancellables = Set<AnyCancellable>()
    var stockValuesPublisher: AnyPublisher<[BasicStockValue], Never> {
            stockValuesSubject.eraseToAnyPublisher()
    }
    
    init(networkService: NetworkServicable = NetworkService()) {
        self.networkService = networkService
        self.setupStocksArraySubscription()
    }
    
    func fetchCurrentInfoForStocks(symbols: [BasicStockValue]) async {
        let dateString = self.previousWeekday(fromDate: Date())
        let urls = self.arrayofURLForStocks(stocks: symbols,
                                            date: dateString)
        Task { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.stockValues = []
            }
            do {
                let returnedStockData = try await self.networkService.fetchMultipleData(urls: urls)
                for datum in returnedStockData {
                    let stockObject: Stock = try jsonDecoder.decode(Stock.self, from: datum)
                    if stockObject.results?.count ?? 0 >= 2 {
                        if let latest = stockObject.latestResult(),
                           let second = stockObject.results?[(stockObject.results!.count) - 2] {
                            let close = latest.closePrice
                            let low = second.closePrice
                            let high = latest.closePrice
                            let date = latest.timestamp
                            let stockObject = BasicStockValue(ticker: stockObject.ticker,
                                                                               daily: close,
                                                                               dailyChange: self.calculateDailyChange(low: low,
                                                                                                                      high: high),
                                                                               date: date)
                            print("stock object with `results = \(stockObject)")
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else { return }
                                self.stockValues.append(stockObject)
                            }
                        }
                    } else {
                        let stockObject = BasicStockValue(ticker: stockObject.ticker, daily: 0.0, dailyChange: 0, date: 0)
                        print("stock object withOUT `results` = \(stockObject)")
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            self.stockValues.append(stockObject)
                        }
                    }
                }
            } catch {
                // TODO: - Handle Error
                print(error)
            }
        }
    }

    private func setupStocksArraySubscription() {
            $stockValues
                .receive(on: RunLoop.main) // Ensure the subscriber code runs on the main thread
                .sink { [weak self] value in
                    guard let self = self else { return }
                    // Access and use `myVariable` safely here, ensured to be on the main thread
                    self.stockValuesSubject.send(value)
                }
                .store(in: &cancellables)
        }
    
    // TODO: -  We would need to account for more scenarios such as holidays as well..this should not be calculated in the client.
    fileprivate func previousWeekday(fromDate: Date) -> String {
        let calendar = Calendar.current
        var dayComponent = DateComponents()
        
        if calendar.component(.weekday, from: fromDate) == 2 {
            dayComponent.day = -3
        } else {
            dayComponent.day = -1
        }
        
        guard let previousWeekday = calendar.date(byAdding: dayComponent, 
                                                  to: fromDate) else {
            fatalError("Error calculating the previous weekday")
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Constants.dateFormat
        return dateFormatter.string(from: previousWeekday)

    }
    
    fileprivate func calculateDailyChange(low: Double, high: Double) -> Double {
        // Note, ideally this would be handled by the server.. the UI should be dumb.
        return Double(round(1000 * (high - low)) / 1000)
    }
    
    fileprivate func formulateURLForSingleBasicStockFrom(urlString: String,
                                      date: String,
                                      ticker: String) -> URL {
        precondition(ProcessInfo.processInfo.environment[Constants.apiKey] != nil)
        let apiKey = ProcessInfo.processInfo.environment[Constants.apiKey]!
        let request: StockDataServiceRequest = StockDataServiceRequest(ticker: ticker,
                                                                       fromDate: date,
                                                                       toDate: date,
                                                                       apiKey: apiKey)
        return request.url
    }
    
    
    // MARK: - Networking For tickerAggregateV2API request
    fileprivate func formulateURLForCompleteStockMarket(urlString: String,
                                      date: String,
                                      ticker: String) -> URL {
        precondition(ProcessInfo.processInfo.environment[Constants.apiKey] != nil)
        let apiKey = ProcessInfo.processInfo.environment[Constants.apiKey]!
        let request: StockDataServiceRequest = StockDataServiceRequest(ticker: ticker, 
                                                                       fromDate: date,
                                                                       toDate: date,
                                                                       apiKey: apiKey)
        return request.url
    }
    
    fileprivate func arrayofURLForStocks(stocks: [BasicStockValue], date: String) -> [URL] {
        var urls: [URL] = []
        for stock in stocks {
            let url = self.formulateURLForSingleBasicStockFrom(urlString: Constants.tickerAggregateV2API, 
                                            date: date,
                                            ticker: stock.ticker)
            urls.append(url)
        }
        return urls
    }
    
    deinit {
        cancellables.removeAll()
    }
}
