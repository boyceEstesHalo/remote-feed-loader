//
//  URLSessionHTTPClientTests.swift
//  
//
//  Created by Boyce Estes on 8/14/21.
//

import Foundation
import XCTest
import NetworkMe

protocol HTTPSession {

    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask
}


protocol HTTPSessionTask {

    func resume()
}


class URLSessionHTTPClient {

    let session: HTTPSession


    init(session: HTTPSession) {
        self.session = session
    }


    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            guard let error = error else { return }
            completion(.failure(error))
        }.resume()
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

        sut.get(from: url) { _ in }

        XCTAssertEqual(task.resumeCount, 1)
    }


    func test_URLSessionHTTPClient_getFromURLWithError_failsOnRequest() {

        let url = URL(string: "https://any-url.com")!
        let error = NSError(domain: "any error", code: 1)
        let session = HTTPSessionSpy()
        session.stub(url: url, error: error)

        let sut = URLSessionHTTPClient(session: session)

        let exp = expectation(description: "Wait for completion")
        sut.get(from: url) { result in
            switch result {
            case .failure(let receivedError as NSError):
                XCTAssertEqual(receivedError, error)
            default:
                XCTFail("Expected an error")
            }

            exp.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }


    // MARK: - Helpers
    private class HTTPSessionSpy: HTTPSession {

        private struct Stub {
            let task: HTTPSessionTask
            let error: Error?
        }
        var receivedURLs = [URL]()
        private var stubs = [URL: Stub]()

        // A stub is used in order to set up some sort of custom logic for some other class to do during tests.
        // In this case, we want to set the data task (or error) that the dataTask call will return inside of
        // the test.
        func stub(url: URL, task: HTTPSessionTask = FakeURLSessionDataTask(), error: Error? = nil) {

            stubs[url] = Stub(task: task, error: error)
        }


        func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask {
            receivedURLs.append(url)

            guard let stub = stubs[url] else {
                fatalError("Expected some stub for url, \(url)")
            }
            completionHandler(nil, nil, stub.error)
            return stub.task
        }
    }


    private class FakeURLSessionDataTask: HTTPSessionTask {

        // Not placing an overloaded resume method would cause a crash when resume was run on
        // this instance.
        func resume() {}
    }


    private class URLSessionDataTaskSpy: HTTPSessionTask {

        var resumeCount = 0

        func resume() {

            resumeCount += 1
        }
    }
}
