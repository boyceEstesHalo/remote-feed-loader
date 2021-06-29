//
//  RemoteFeedLoader.swift
//  
//
//  Created by Boyce Estes on 6/24/21.
//

import Foundation




public protocol HTTPClient {

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}


public enum HTTPClientResult {

    case success(Data, HTTPURLResponse)
    case failure(Error)
}


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

        client.get(from: url) { result in

            switch result {
            case .success(let data, let response):

                if response.statusCode == 200, let root = try? JSONDecoder().decode(Root.self, from: data) {
                    completion(.success(root.items.map { $0.item }))
                } else {
                    completion(.failure(.invalidData))
                }

            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}


private struct Root: Decodable {

    let items: [Item]
}


private struct Item: Decodable {

    let id: UUID
    let description: String?
    let location: String?
    let image: URL  // image name should be exactly the same as API expects.
    // This allows us to keep the module decoupled from the FeedLoader module.
    // This way other FeedLoaders do not conform to the same CodingKeys.


    // Now you must map through these items to turn them in to the appropriate
    // FeedItems that are expected.
    var item: FeedItem {

        FeedItem(
            id: id,
            description: description,
            location: location,
            imageURL: image
        )
    }
}
