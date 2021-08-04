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

        expect(sut, toCompleteWithResult: .failure(RemoteFeedLoader.Error.connectivity)) {

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

            expect(sut, toCompleteWithResult: .failure(RemoteFeedLoader.Error.invalidData)) {

                let itemsJSON = makeItemsJSON([])
                client.complete(with: code, data: itemsJSON, index: index)
            }
        }
    }


    func test_load_ok200ResponseWithInvalidJSON_deliversInvalidError() {

        // given
        let (sut, client) = makeSUT()

        // when/then
        expect(sut, toCompleteWithResult: .failure(RemoteFeedLoader.Error.invalidData)) {
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

            let jsonData = makeItemsJSON([])
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

            let json = makeItemsJSON([item1.json, item2.json])
            client.complete(with: 200, data: json)
        }
    }


    func test_load_RemoteFeedLoaderDeallocatedWhileHTTPClientIsWorking_noResultReturned() {

        // given
        let url = URL(string: "https://some-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)

        var capturedResults = [Result<[FeedItem], Error>]()
        sut?.load { capturedResults.append($0) }
        sut = nil

        client.complete(with: 200, data: makeItemsJSON([]))
        XCTAssertTrue(capturedResults.isEmpty)
    }


    // MARK: Helpers

    private func makeSUT(url: URL = URL(string: "https://a-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (RemoteFeedLoader, HTTPClientSpy) {

        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)

        // Teardown block allows us to do something at the end of a test. We place it in
        // this test case instead of in a tearDown method because we only want to test this
        // when the SUT is in memory.
        addTeardownBlock { [weak sut] in
            // We make sut weak here because we do not want to keep it in memory
            // if it is not already in memory. If we didn't make it weak, functions that
            // do not have retain cycles from the load method (like
            // test_init_doesNotRequestDataFromURL) will fail this test.

            XCTAssertNil(sut, file: file, line: line)
        }

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


    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {

        let itemsJSON = [ "items": items ]
        return try! JSONSerialization.data(withJSONObject: itemsJSON)
    }


    private func expect(
        _ sut: RemoteFeedLoader,
        toCompleteWithResult expectedResult: Result<[FeedItem], Error>,
        when action: () -> Void,
        file: StaticString = #file, line: UInt = #line) {

        // when

        // There is a problem in asserting equal on a nonequatable error
        // We want to keep the error generic for now.
        // To handle this we can handle checking whether the expectedResult
        // is the same as the actual result in the completion handler of the
        // load method.
        let exp = expectation(description: "Wait for load to complete.")
        sut.load { receivedResult in

            // then
            switch (receivedResult, expectedResult) {
            case (.success(let receivedItems), .success(let expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems)
            case (.failure(let receivedError as RemoteFeedLoader.Error), .failure(let expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectedError)
            default:
                XCTFail("Expected result, \(expectedResult), did not match actual result, \(receivedResult)")
            }

            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 1.0)
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

