//
//  FeedItem.swift
//  
//
//  Created by Boyce Estes on 6/16/21.
//

import Foundation

public struct FeedItem: Equatable {

    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageURL: URL

    public init(description: String?, location: String?, imageURL: URL) {

        self.id = UUID()
        self.description = description
        self.location = location
        self.imageURL = imageURL
    }
}

extension FeedItem: Decodable {

    private enum CodingKeys: String, CodingKey {
        case id
        case description
        case location
        case imageURL = "image"
    }
}
