//
//  PolygonStockTrackerApp.swift
//  PolygonStockTracker
//
//  Created by Randy McLain on 3/1/24.
//

import SwiftUI

@main
struct PolygonStockTrackerApp: App {
    
    @Environment(\.scenePhase) private var scenePhase

    let networkService = NetworkService(session: URLSession(configuration: URLSessionConfiguration.customWithTimeoutInterval()))
    let stockService: BasicStockOverviewService
    let persistanceService = PersistenceService()
    
    init() {
        self.stockService = BasicStockOverviewService(networkService: networkService)
    }
    var body: some Scene {
        WindowGroup {
            StocksOverview(stockService,
                           persistence: persistanceService,
                           networkService: networkService)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task {
                    let stocks = await self.persistanceService.awaitStoredStockValues()
                    await self.stockService.fetchCurrentInfoForStocks(symbols:stocks)
                }
            } else {
                // TODO: - ERROR HANDLING: save persistent state to User Defaults.
            }
        }
    }
}

extension URLSessionConfiguration {
    static func customWithTimeoutInterval(_ timeoutSeconds: TimeInterval = 120) -> URLSessionConfiguration {
         let configuration = URLSessionConfiguration.default
         configuration.timeoutIntervalForRequest = timeoutSeconds
         return configuration
     }
}
