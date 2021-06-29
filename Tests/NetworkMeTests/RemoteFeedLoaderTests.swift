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

        expect(sut, toCompleteWithResult: .failure(.connectivity)) {

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

            expect(sut, toCompleteWithResult: .failure(.invalidData)) {

                let itemsJSON = makeItemJSON([])
                client.complete(with: code, data: itemsJSON, index: index)
            }
        }
    }


    func test_load_ok200ResponseWithInvalidJSON_deliversInvalidError() {

        // given
        let (sut, client) = makeSUT()

        // when/then
        expect(sut, toCompleteWithResult: .failure(.invalidData)) {
            let badJSON = Data("Invlaid JSON".utf8)
            let code = 200
            client.complete(with: code, data: badJSON)
        }

    }


    func test_load_ok200ResponseWithEmptyList_deliversNoItems() {

        // given
        let (sut, client) = makeSUT()

        // when/then
        expect(sut, toCompleteWithResult: .success([])) {

            let jsonData = makeItemJSON([])
            client.complete(with: 200, data: jsonData)
        }
    }


    func test_load_ok200ResponseWithFeedItems_deliversDecodedFeedItems() {

        // given
        let (sut, client) = makeSUT()

        let item1 = makeItem(
            id: UUID(),
            imageURL: URL(string: "image.com")!)

        let item2 = makeItem(
            id: UUID(),
            description: "A description",
            location: "A location",
            imageURL: URL(string: "image2.com")!
        )


        let items = [item1.model, item2.model]

        // when/then
        expect(sut, toCompleteWithResult: .success(items)) {

            let json = makeItemJSON([item1.json, item2.json])
            client.complete(with: 200, data: json)
        }
    }


    // MARK: Helpers

    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {

        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }


    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {

        let item = FeedItem(
            id: id,
            description: description,
            location: location,
            imageURL: imageURL)

        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].compactMapValues { $0 }

        return (item, json)
    }


    private func makeItemJSON(_ items: [[String: Any]]) -> Data {

        let itemsJSON = [ "items": items ]
        return try! JSONSerialization.data(withJSONObject: itemsJSON)
    }


    private func expect(_ sut: RemoteFeedLoader, toCompleteWithResult result: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {

        // when
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append($0) }

        action()

        // then
        XCTAssertEqual(capturedResults, [result], file: file, line: line)
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


        func complete(with statusCode: Int, data: Data, index: Int = 0) {

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

