//
//  ContentView.swift
//  PolygonStockTracker
//
//  Created by Randy McLain on 3/1/24.
//

import SwiftUI
import Combine

struct StocksOverview: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var viewModel: ViewModel
    private var networkService: NetworkServicable
    
    init(_ stockService: BasicStockOverviewService = BasicStockOverviewService(),
        persistence: Storable,
         networkService: NetworkServicable) {
        self.viewModel = ViewModel(networkService: networkService, 
                                   persistence: persistence,
                                   stockService: stockService)
        self.networkService = networkService
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    List {
                        ForEach(self.viewModel.stocks, id: \.ticker) { stock in // cannot use capture list here non escaping closure..
                            NavigationLink {
                                StockDetailView(stock: stock,
                                                networkService:  self.networkService)
                            } label: {
                                HStack() {
                                    Text(stock.ticker)
                                    Spacer()
                                    CurrentStockValueView(price: stock.daily,
                                                          change: "+ \(stock.dailyChange)")
                                }
                            }
                        }
                    }
                    .padding()
                }
                .onAppear {
                    self.viewModel.updateLocalStocks()
                }
                .refreshable {
                    Task {
                        await self.viewModel.fetchUpdatedStocks()
                    }
                    print("Pull to refresh")
                }
                .navigationBarTitle("StocksOverview", displayMode: .inline)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink("Stocks", destination: {
                            ListOfStocksView(persistence: self.viewModel.persistenceService,
                                             networkService: self.networkService)
                        })
                        .foregroundColor(.gray)
                    }
                }
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    .scaleEffect(viewModel.stocksLoading ? 2 : 0)
                    .frame(height: viewModel.stocksLoading ? 20 : 0)
                    .opacity(viewModel.stocksLoading ? 1: 0)
            }

        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                print("App sent to background")
                // Typically persistence layer would be cached here.
            }
        }
        .onDisappear {
            self.viewModel.closeLoadingState()
            print("Close loading state")
        }
    }
}

struct CurrentStockValueView: View {
    let price: Double
    let change: String
    
    var body: some View {
        VStack {
            Text(self.checkForPrice(price: price))
            Text(change)
        }
        .font(Font.footnote)
        .padding()
    }
    
    func checkForPrice(price: Double) -> String {
        if (price == 0.0) {
            return "--"
        } else {
            return String(price)
        }
    }
}

#Preview {
    StocksOverview(BasicStockOverviewService(), persistence: PersistenceService(), networkService: NetworkService())
}
