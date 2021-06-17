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
        HTTPClientSpy.shared.get(from: URL(string: "https://some-api")!)
    }
}


class HTTPClient {

    static var shared = HTTPClient()

    func get(from url: URL) {}
}


class HTTPClientSpy: HTTPClient {

    var requestedURL: URL?

    override func get(from url: URL) {

        requestedURL = url
    }
}


class RemoteFeedLoaderTests: XCTestCase {


    // when we are using RemoteFeedLoader, there are a couple key factors
    // input: some URL that will retrieve some data using some HTTPClient
    // output: some FeedItem

    // Make sure that we do not have a requestedURL in the HTTPClient without calling load
    // by the remoteFeedLoader.
    func test_init_doesNotRequestDataFromURL() {

        let client = HTTPClientSpy()
        HTTPClient.shared = client
        let _ = RemoteFeedLoader()

        XCTAssertNil(client.requestedURL)
    }

    // We need to connect the client to the feed loader somehow so that we can change
    // the HTTPClient's requestedURL from the RemoteFeedLoader.
    // Possible through dependency injection (initializer injection, property injection, or method injection)
    // Or we could make HTTPClient a singleton so that it is available everywhere.
    func test_load_requestDataFromURL() {

        let client = HTTPClientSpy()
        HTTPClient.shared = client
        let sut = RemoteFeedLoader()

        sut.load()

        XCTAssertNotNil(client.requestedURL)
    }

    // There is no good reason that there cannot be multiple HTTPClients.

    // The goal is to get rid of the singleton so that we can mock the HTTPClient.
    // One way to do this:

    // Change this singleton we can make `shared` mutable. This makes this a global state
    // since it can be changed. This is useful because we don'
}

