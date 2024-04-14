//
//  StockDetailView.swift
//  PolygonStockTracker
//
//  Created by Randy McLain on 3/2/24.
//

import SwiftUI
import Charts

struct StockDetailView: View {
    
    @ObservedObject var viewModel: ViewModel
    init(stock: BasicStockValue,
            persistence: Storable = PersistenceService(),
         networkService: NetworkServicable) {
        self.viewModel = ViewModel(persistenceService: persistence,
                                   stockService: HistoricalStockDataService(networkService: networkService,
                                                                            stockValue: stock),
                                   basicStockValue: stock)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                    Chart(self.viewModel.seriesData, id: \.id) { series in
                        BarMark(
                            x: .value(Constants.day, series.date, unit: .day),
                            y: .value(Constants.price, series.price)
                        )
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.day(), centered: true)
                    }
                }
                HStack {
                    Spacer()
                    Text(Constants.volume)
                    Spacer()
                    Text(String(self.viewModel.stock?.results?.first?.volume ?? 0) )
                    Spacer()
                }
                .padding()
                HStack {
                    Spacer()
                    Text(Constants.marketCap)
                    Spacer()
                    Text(self.setupMarketCapFor(stock: self.viewModel.basicStockValue))
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitle(self.viewModel.basicStockValue.ticker, displayMode: .inline)
            .padding()
        }
        .navigationTitle(Constants.stockdetail)
        .onAppear {
            Task { // cannot use capture list here. 
                await self.viewModel.fetchHistoricalStockData(self.viewModel.basicStockValue)
            }
        }
    }
    
    func setupMarketCapFor(stock: BasicStockValue) -> String {
        if let marketCap = stock.marketCap {
            return String(marketCap)
        } else {
            return "--"
        }
    }
}

#Preview {
    StockDetailView(stock: BasicStockValue(ticker: "AAPL", daily: 0, dailyChange: 0, date: 0), networkService: NetworkService())
}
