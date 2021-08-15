//
//  URLSessionHTTPClientTests.swift
//  
//
//  Created by Boyce Estes on 8/14/21.
//

import Foundation
import XCTest

class URLSessionHTTPClient {

    let session: URLSession


    init(session: URLSession) {
        self.session = session
    }


    func get(from url: URL) {

        session.dataTask(with: url) { _, _, _ in }
    }
}


class URLSessionHTTPClientTests: XCTestCase {

    func test_URLSessionHTTPClient_getFromURL_createsDataTaskWithURL() {
        let url = URL(string: "https://any-url.com")!
        let session = HTTPSessionSpy()
        let sut = URLSessionHTTPClient(session: session)

        sut.get(from: url)

        XCTAssertEqual(session.receivedURLs, [url])
    }


    // MARK: - Helpers
    private class HTTPSessionSpy: URLSession {
        var receivedURLs = [URL]()

        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            receivedURLs.append(url)
            return FakeURLSessionDataTask()
        }
    }


    private class FakeURLSessionDataTask: URLSessionDataTask {

    }
}
