//
//  RemoteFeedLoader.swift
//  
//
//  Created by Boyce Estes on 6/24/21.
//

import Foundation


public final class RemoteFeedLoader {

    private let url: URL
    private let client: HTTPClient


    public enum Error: Swift.Error {

        case connectivity
        case invalidData
    }


    public enum Result:Equatable {

        case success([FeedItem])
        case failure(Error)
    }
    

    public init(url: URL, client: HTTPClient) {

        self.url = url
        self.client = client
    }


    public func load(completion: @escaping (Result) -> Void) {

        client.get(from: url) { [weak self] result in
            guard self != nil else { return }

            switch result {
            case .success(let data, let response):

                completion(FeedItemsMapper.map(data: data, response: response))

            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}
