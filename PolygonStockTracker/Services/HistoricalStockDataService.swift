//
//  HistoricalStockDataService.swift
//  PolygonStockTracker
//
//  Created by Randy McLain on 3/5/24.
//

import Foundation
import Combine

class HistoricalStockDataService {
    
    private var stockValuesSubject = PassthroughSubject<Stock, Never>() // TODO: This is where error handling would begin
    private var basicStockValuesSubject = PassthroughSubject<BasicStockValue, Never>() // TODO: This is where error handling would begin
    let networkService: NetworkServicable
    private let jsonDecoder: JSONDecoder = JSONDecoder()
    
    @Published private var stock: Stock?
    @Published private var stockValue: BasicStockValue
    private var cancellables = Set<AnyCancellable>()
    var stockValuesPublisher: AnyPublisher<Stock, Never> { // TODO: This is where error handling would begin
            stockValuesSubject.eraseToAnyPublisher()
    }
    
    var basicStockValuesPublisher: AnyPublisher<BasicStockValue, Never> { // TODO: This is where error handling would begin
            basicStockValuesSubject.eraseToAnyPublisher()
    }
    
    init(networkService: NetworkServicable,
         stockValue: BasicStockValue) {
        self.networkService = networkService
        self.stockValue = stockValue
        self.setupSubscriptions()
    }
    
    func fetchHistoricalInfoForStocks(symbol: BasicStockValue) async {
        let url = formulateURLForHistoricalAPICallFrom(urlString: Constants.tickerAggregateV2API, 
                                                       fromDate: self.fifteenDaysPervious(fromDate: Date()),
                                                       toDate: todaysStringDate(),
                                                       ticker: symbol.ticker)
        do {
            let data = try await self.networkService.attemptdataFor(url: url)
            let stockObject: Stock = try jsonDecoder.decode(Stock.self, from: data)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.stock = stockObject
            }
        } catch {
            print(error)
        }
    }
    
    func fetchMarketCapInfoForStock(symbol: BasicStockValue) async {
        let url = formulateURLForMarketCapAPICall(ticker: symbol.ticker)
        
        let now = Date()
        let timeSince1970 = Int64(now.timeIntervalSince1970 * 1000) // milliseconds 
        
        do {
            let data = try await self.networkService.attemptdataFor(url: url)
            let stockObject: StockDetail = try jsonDecoder.decode(StockDetail.self, from: data)
            let newStock = BasicStockValue(ticker: symbol.ticker,
                                           daily: symbol.daily,
                                           dailyChange: symbol.dailyChange,
                                           date: Int(timeSince1970),
                                           marketCap: stockObject.results.marketCap)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.stockValue = newStock
            }
        } catch {
            print(error)
        }
    }
    
    private func setupSubscriptions() {
        $stock
            .receive(on: RunLoop.main)
            .sink { [weak self] stock in
                guard let self = self else { return }
                if let updatedStock = stock {
                    self.stockValuesSubject.send(updatedStock)
                } else {
                    // TODO: -  error handling here.
                }
            }
            .store(in: &cancellables)
        
        $stockValue
            .receive(on: RunLoop.main)
            .sink { [weak self] stockValue in
                guard let self = self else { return }
                self.basicStockValuesSubject.send(stockValue)
            }
            .store(in: &cancellables)
    }
    
    // TODO: - Move this out to a service class
    fileprivate func todaysStringDate() -> String {
        let now = Date()
        let timeSince1970 = Int64(now.timeIntervalSince1970 * 1000)
        return String(timeSince1970)
    }
    
    // TODO: -  We would need to account for more scenarios such as holidays as well..this should not be calculated in the client.
    // this is a limitation from the free tier data preventing us from attempting to access todays data and getting an error.
    fileprivate func previousWeekday(fromDate: Date) -> String {
        let calendar = Calendar.current
        var dayComponent = DateComponents()
        
        if calendar.component(.weekday, from: fromDate) == 2 { // its monday
            dayComponent.day = -3 // dealing with weekends
        } else {
            dayComponent.day = -1 // limitation from API preventing todays data from being available
        }
        
        guard let previousWeekday = calendar.date(byAdding: dayComponent,
                                                  to: fromDate) else {
            fatalError("Error calculating the previous weekday")
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Constants.dateFormat
        return dateFormatter.string(from: previousWeekday)
    }
    
    fileprivate func fifteenDaysPervious(fromDate: Date) -> String {

        let now = Date()

        let calendar = Calendar.current
        guard  let ninetyDaysAgo = calendar.date(byAdding: .day, value: -15, to: now) else {
            fatalError("Error calculating the previous ninety days")
        }

        let millisecondsSince1970ForNinetyDaysAgo = Int64(ninetyDaysAgo.timeIntervalSince1970 * 1000)
        return String(millisecondsSince1970ForNinetyDaysAgo)
    }
    
    fileprivate func formulateURLForMarketCapAPICall(ticker: String) -> URL {
        let date = previousWeekday(fromDate: Date())
        
        precondition(ProcessInfo.processInfo.environment[Constants.apiKey] != nil)
        let apiKey = ProcessInfo.processInfo.environment[Constants.apiKey]!
        let request = StockDetailRequest(date: date, apiKey: apiKey, ticker: ticker)
        return request.url
        
    }
    
    fileprivate func formulateURLForHistoricalAPICallFrom(urlString: String,
                                                          fromDate: String,
                                                          toDate: String,
                                                          ticker: String) -> URL {
        precondition(ProcessInfo.processInfo.environment[Constants.apiKey] != nil)
        let apiKey = ProcessInfo.processInfo.environment[Constants.apiKey]!
        let request = HistoricalAggregateRequest(ticker: ticker,
                                                 fromDate: fromDate,
                                                 toDate: toDate,
                                                 apiKey: apiKey)
        return request.url
    }
    
    deinit {
        cancellables.removeAll()
    }
}
