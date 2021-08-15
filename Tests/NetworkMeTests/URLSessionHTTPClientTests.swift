//
//  URLSessionHTTPClientTests.swift
//  
//
//  Created by Boyce Estes on 8/14/21.
//

import Foundation
import XCTest
import NetworkMe


class URLSessionHTTPClient {

    let session: URLSession


    init(session: URLSession = .shared) {
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

    func test_URLSessionHTTPClient_getFromURLWithError_failsOnRequest() {
        // register and unregister the URLProtocol to make the URLSession use this.
        URLProtocolStub.startInterceptingRequests()
        let url = URL(string: "https://any-url.com")!
        let error = NSError(domain: "any error", code: 1)

        URLProtocolStub.stub(url: url, error: error)
        let sut = URLSessionHTTPClient()

        let exp = expectation(description: "Wait for completion")
        sut.get(from: url) { result in
            switch result {
            case .failure(let receivedError as NSError):
                // in iOS 14 receivedError is returned as different NSError instances.
                XCTAssertEqual(receivedError.domain, error.domain)
                XCTAssertEqual(receivedError.code, error.code)
            default:
                XCTFail("Expected an error")
            }

            exp.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
        URLProtocolStub.stopInterceptingRequests()
    }


    // MARK: - Helpers
    private class URLProtocolStub: URLProtocol {

        private struct Stub {
            let error: Error?
        }

        private static var stubs = [URL: Stub]()

        // A stub is used in order to set up some sort of custom logic for some other class to do during tests.
        // In this case, we want to set the data task (or error) that the dataTask call will return inside of
        // the test.
        static func stub(url: URL, error: Error? = nil) {

            stubs[url] = Stub(error: error)
        }


        static func startInterceptingRequests() {

            URLProtocol.registerClass(URLProtocolStub.self)
        }


        static func stopInterceptingRequests() {

            URLProtocol.unregisterClass(URLProtocolStub.self)
            stubs = [:]
        }


        override class func canInit(with request: URLRequest) -> Bool {

            guard let url = request.url else { return false }
            return stubs[url] != nil
        }


        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }


        override func startLoading() {
            guard let url = request.url, let stub = URLProtocolStub.stubs[url] else { return }

            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }

            client?.urlProtocolDidFinishLoading(self)
        }


        override func stopLoading() {}
    }
}
