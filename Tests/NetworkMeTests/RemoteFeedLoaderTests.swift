//
//  RemoteFeedLoaderTests.swift
//  
//
//  Created by Boyce Estes on 6/16/21.
//

import XCTest


class RemoteFeedLoader {

}


class HTTPClient {


    var requestedURL: URL?
}


class RemoteFeedLoaderTests: XCTestCase {


    // when we are using RemoteFeedLoader, there are a couple key factors
    // input: some URL that will retrieve some data using some HTTPClient
    // output: some FeedItem

    // Make sure that we do not have a requestedURL in the HTTPClient without calling load
    // by the remoteFeedLoader.
    func test_init_doesNotRequestDataFromURL() {

        let client = HTTPClient()
        let _ = RemoteFeedLoader()

        XCTAssertNil(client.requestedURL)
    }
}
