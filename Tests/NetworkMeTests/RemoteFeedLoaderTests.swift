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

        XCTAssertTrue(client.requestedURLs.isEmpty)
    }


    func test_load_once_requestsDataFromURLOnce() {

        let url = URL(string: "https://a-specific-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load { _ in }

        XCTAssertEqual(client.requestedURLs, [url])
    }


    func test_load_twice_requestsDataFromURLTwice() {

        let url = URL(string: "https://a-specific-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load { _ in }
        sut.load { _ in }

        XCTAssertEqual(client.requestedURLs, [url, url])
    }


    func test_load_clientError_deliversError() {

        // given
        let (sut, client) = makeSUT()

        // when
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0) }

        let clientError = NSError(domain: "Test", code: 0)
        client.complete(with: clientError)

        // then
        XCTAssertEqual(capturedErrors, [.connectivity])
    }


    func test_load_non200Response_deliversInvalidError() {

        // given
        let (sut, client) = makeSUT()

        // when
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0) }

        client.complete(with: 400)

        // then
        XCTAssertEqual(capturedErrors, [.invalidData])
    }


    // MARK: Helpers

    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {

        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }


    class HTTPClientSpy: HTTPClient {

        var messages = [(url: URL, completion: (Error?, HTTPURLResponse?) -> Void)]()

        var requestedURLs: [URL] {

            messages.map { $0.url }
        }


        func get(from url: URL, completion: @escaping (Error?, HTTPURLResponse?) -> Void) {

            messages.append((url, completion))
        }


        func complete(with error: Error, index: Int = 0) {


            messages[index].completion(error, nil)
        }


        func complete(with statusCode: Int, index: Int = 0) {

            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )
            messages[index].completion(nil, response)
        }
    }
}

