//
//  RemoteFeedLoaderTests.swift
//  
//
//  Created by Boyce Estes on 6/16/21.
//

import XCTest


class RemoteFeedLoader {

    func load() {

        // Modify the HTTPClient singleton:
        HTTPClient.shared.requestedURL = URL(string: "https://some-api")
    }
}


class HTTPClient {

    static let shared = HTTPClient()
    var requestedURL: URL?

    private init() {}
}


class RemoteFeedLoaderTests: XCTestCase {


    // when we are using RemoteFeedLoader, there are a couple key factors
    // input: some URL that will retrieve some data using some HTTPClient
    // output: some FeedItem

    // Make sure that we do not have a requestedURL in the HTTPClient without calling load
    // by the remoteFeedLoader.
    func test_init_doesNotRequestDataFromURL() {

        let client = HTTPClient.shared
        let _ = RemoteFeedLoader()

        XCTAssertNil(client.requestedURL)
    }

    // We need to connect the client to the feed loader somehow so that we can change
    // the HTTPClient's requestedURL from the RemoteFeedLoader.
    // Possible through dependency injection (initializer injection, property injection, or method injection)
    // Or we could make HTTPClient a singleton so that it is available everywhere.
    func test_load_requestDataFromURL() {

        let client = HTTPClient.shared
        let sut = RemoteFeedLoader()

        sut.load()

        XCTAssertNotNil(client.requestedURL)
    }
}

