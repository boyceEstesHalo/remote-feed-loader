//
//  NetworkMeAPIEndToEndTests.swift
//  
//
//  Created by Boyce Estes on 8/22/21.
//
import XCTest
import NetworkMe


class NetworkMeAPIEndToEndTests: XCTestCase {

    func test_feedLoader_endToEndTestServerGETResult_matchesFixedTestAccountData() {

        let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
        let client = URLSessionHTTPClient()
        let loader = RemoteFeedLoader(url: testServerURL, client: client)

        let exp = expectation(description: "Completes loading operation")

        var receivedResult: Result<[FeedItem], Error>?
        loader.load { result in
            receivedResult = result

            exp.fulfill()
        }

        wait(for: [exp], timeout: 5)

        switch receivedResult {
        case .success(let items):
            XCTAssertEqual(items.count, 8)

        case .failure(let error):
            XCTFail("Expected success but received \(error) instead")

        default:
            XCTFail("Expected success but received nothing instead")
        }
    }
}
