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
            guard let self = self else { return }

            switch result {
            case .success(let data, let response):

                completion(self.map(data: data, response: response))

            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }


    private func map(data: Data, response: HTTPURLResponse) -> Result {

        do {
            let feedItems = try FeedItemsMapper.map(data, response)
            return .success(feedItems)
        } catch {
            return .failure(.invalidData)
        }
    }
}

private class FeedItemsMapper {

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

    // MARK: Properties
    static var OK_200: Int { return 200 }


    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {

        guard response.statusCode == OK_200 else {
            throw RemoteFeedLoader.Error.invalidData
        }

        return try JSONDecoder().decode(Root.self, from: data).items.map { $0.item }
    }
}
