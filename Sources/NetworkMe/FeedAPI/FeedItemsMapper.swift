//
//  File.swift
//  
//
//  Created by Boyce Estes on 6/30/21.
//

import Foundation

internal class FeedItemsMapper {

    private struct Root: Decodable {

        let items: [Item]

        var feedItems: [FeedItem] {
            self.items.map { $0.item }
        }
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
    private static var OK_200: Int { return 200 }

    internal static func map(data: Data, response: HTTPURLResponse) -> Result<[FeedItem], Error> {

        if response.statusCode == OK_200,
           let root = try? JSONDecoder().decode(Root.self, from: data) {

            let feedItems = root.feedItems
            return .success(feedItems)
        } else {
            return .failure(RemoteFeedLoader.Error.invalidData)
        }
    }
}
