//
//  NetworkService.swift
//  PolygonStockTracker
//
//  Created by Randy McLain on 3/1/24.
//

import Foundation
import Combine

enum NetworkServiceError: Error, Equatable {
    case HttpUrlErrorResponse
    case RateLimitedByServer
    case HttpUrlResponseErrorCode(_ code: Int)
}

protocol NetworkServicable {
    func attemptdataFor(url: URL) async throws -> Data
    func fetchMultipleData (urls: [URL]) async throws -> [Data]
}

class NetworkService: NetworkServicable {
    
    
    // MARK: - Properties
    private let session: URLSession
    private var cancellables = Set<AnyCancellable>()
    private var dataTaskPublisher: URLSession.DataTaskPublisher?
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func attemptdataFor(url: URL) async throws -> Data {
        try await Task.retrying(
            where: { error in (error as? NetworkServiceError) == .RateLimitedByServer },
            maxRetryCount: 3,
            retryDelay: 20,
            timeoutInSeconds: 60
        ) {
            try await self.asyncDataFetchForURL(url:url)
        }
        .value
    }
    
    private func asyncDataFetchForURL(url: URL) async throws -> Data {
       
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkServiceError.HttpUrlErrorResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return data
        case 429:
            throw NetworkServiceError.RateLimitedByServer
        default:
            throw NetworkServiceError.HttpUrlResponseErrorCode(httpResponse.statusCode)
        }
        
    }
    
   
    private func fetchdataFor(url: URL) async throws -> AnyPublisher<Data, Error> {
        return session.dataTaskPublisher(for: url)
            .tryMap { element -> Data in
                guard let httpResponse = element.response as? HTTPURLResponse else {
                    throw NetworkServiceError.HttpUrlErrorResponse
                }
                switch httpResponse.statusCode {
                case 429:
                    throw NetworkServiceError.RateLimitedByServer
                case 200:
                    return element.data
                default:
                    throw NetworkServiceError.HttpUrlResponseErrorCode(httpResponse.statusCode)
                }
            }
            .retry(3)
            .eraseToAnyPublisher()
    }
    
    

    func fetchMultipleData (urls: [URL]) async throws -> [Data] {
            
            // TODO: - 1. Append these to the ordered URL array!
        var orderedResults: [String: Data] = [:]
        for url in urls {
            print("fetch multiple data for url: \(url) will add attemptDataForURL to Task")
            let data = try await self.attemptdataFor(url: url)
            orderedResults[url.path()] = data
 
        }
        print("returning ordered results = \(orderedResults)")
        return Array(orderedResults.values)
    }
    
    deinit {
        self.cancellables.removeAll()
        self.session.finishTasksAndInvalidate()
    }
}


