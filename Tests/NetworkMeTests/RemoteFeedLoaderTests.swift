//
//  RemoteFeedLoaderTests.swift
//  
//
//  Created by Boyce Estes on 6/16/21.
//

import XCTest
import NetworkMe






class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {

        let (_, client) = makeSUT()

        XCTAssertNil(client.requestedURL)
    }


    func test_load_requestsDataFromURL() {

        let url = URL(string: "https://a-specific-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load()

        XCTAssertEqual(client.requestedURL, url)
    }


    // MARK: Helpers

    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {

        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }


    class HTTPClientSpy: HTTPClient {

        var requestedURL: URL?

        func get(from url: URL) {

            requestedURL = url
        }
    }

}

