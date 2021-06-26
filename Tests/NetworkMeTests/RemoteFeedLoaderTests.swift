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

        expect(sut, toCompleteWithError: .connectivity) {

            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        }
    }


    func test_load_non200Response_deliversInvalidError() {

        // given
        let (sut, client) = makeSUT()

        // when/then
        let samples = [199, 201, 300, 400, 500]

        samples.enumerated().forEach { index, code in

            expect(sut, toCompleteWithError: .invalidData) {
                client.complete(with: code, index: index)
            }
        }
    }


    func test_load_ok200ResponseWithInvalidJSON_deliversInvalidError() {

        // given
        let (sut, client) = makeSUT()

        // when/then
        expect(sut, toCompleteWithError: .invalidData) {
            let badJSON = Data("Invlaid JSON".utf8)
            let code = 200
            client.complete(with: code, data: badJSON)
        }

    }


    // MARK: Helpers

    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {

        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }


    private func expect(_ sut: RemoteFeedLoader, toCompleteWithError error: RemoteFeedLoader.Error, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {

        // when
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0) }


        action()

        // then
        XCTAssertEqual(capturedErrors, [error], file: file, line: line)
    }


    class HTTPClientSpy: HTTPClient {

        var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()

        var requestedURLs: [URL] {

            messages.map { $0.url }
        }


        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {

            messages.append((url, completion))
        }


        func complete(with error: Error, index: Int = 0) {

            messages[index].completion(.failure(error))
        }


        func complete(with statusCode: Int, data: Data = Data(), index: Int = 0) {

            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!

            messages[index].completion(.success(data, response))
        }
    }
}

