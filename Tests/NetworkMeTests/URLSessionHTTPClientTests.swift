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

        session.dataTask(with: url) { _, _, _ in }.resume()
    }
}


class URLSessionHTTPClientTests: XCTestCase {

    func test_URLSessionHTTPClient_getFromURL_resumesDataTaskWithURL() {

        // Make sure that we are only resuming one time.
        let url = URL(string: "https://any-url.com")!
        let session = HTTPSessionSpy()
        let task = URLSessionDataTaskSpy()
        session.stub(url: url, task: task)

        let sut = URLSessionHTTPClient(session: session)

        sut.get(from: url)

        XCTAssertEqual(task.resumeCount, 1)
    }


    // MARK: - Helpers
    private class HTTPSessionSpy: URLSession {
        var receivedURLs = [URL]()
        private var stubs = [URL: URLSessionDataTask]()

        // A stub is a method of inserting/replacing some functionality in a class, usually for testing purposes.
        // In this case we want to replace the usual functionality of a simple URLSessionDataTask with our
        // URLSessionDataTaskSpy. The stub will need to be created before the session calls this method so the url
        // will be in place. Otherwise it will give a fatal error.
        func stub(url: URL, task: URLSessionDataTask) {

            stubs[url] = task
        }


        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            receivedURLs.append(url)

            return stubs[url] ?? FakeURLSessionDataTask()
        }
    }


    private class FakeURLSessionDataTask: URLSessionDataTask {

        // Not placing an overloaded resume method would cause a crash when resume was run on
        // this instance.
        override func resume() {}
    }


    private class URLSessionDataTaskSpy: URLSessionDataTask {

        var resumeCount = 0

        override func resume() {

            resumeCount += 1
        }
    }
}
