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

    struct UnexpectedValuesRepresentation: Error {}

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in

            if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }
}


class URLSessionHTTPClientTests: XCTestCase {

    override func setUp() {

        super.setUp()

        URLProtocolStub.startInterceptingRequests()
    }


    override func tearDown() {

        super.tearDown()

        URLProtocolStub.stopInterceptingRequests()
    }


    func test_URLSessionHTTPClient_getFromURL_performsGetRequestWithURL() {

        let url = anyURL()
        let exp = expectation(description: "Wait for request")

        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }

        makeSUT().get(from: url) { _ in }

        wait(for: [exp], timeout: 1.0)

    }


    func test_URLSessionHTTPClient_getWithError_failsOnRequest() {

        // register and unregister the URLProtocol to make the URLSession use this.
        let error = NSError(domain: "any error", code: 1)

        let receivedError = resultErrorFor(data: nil, response: nil, error: error) as NSError?

        XCTAssertEqual(receivedError?.domain, error.domain)
        XCTAssertEqual(receivedError?.code, error.code)
    }


    func test_URLSessionHTTPClient_getFromURL_failsOnAllNilValues() {

        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
    }



    // MARK: - Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> URLSessionHTTPClient {

        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }


    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Error? {

        URLProtocolStub.stub(data: data, response: response, error: error)

        let sut = makeSUT(file: file, line: line)
        let exp = expectation(description: "Wait for completion")
        var receivedError: Error?

        sut.get(from: anyURL()) { result in
            switch result {
            case .failure(let error):
                receivedError = error
            default:
                XCTFail("Expected failure, got \(result) instead", file: file, line: line)
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
        return receivedError
    }


    private func anyURL() -> URL {
        return URL(string: "https://any-url.com")!
    }


    private class URLProtocolStub: URLProtocol {

        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }

        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?

        // A stub is used in order to set up some sort of custom logic for some other class to do during tests.
        // In this case, we want to set the data task (or error) that the dataTask call will return inside of
        // the test.
        static func stub(data: Data?, response: URLResponse?, error: Error? = nil) {

            stub = Stub(data: data, response: response, error: error)
        }


        static func startInterceptingRequests() {

            URLProtocol.registerClass(URLProtocolStub.self)
        }


        static func stopInterceptingRequests() {

            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }


        static func observeRequests(observer: @escaping (URLRequest) -> Void) {

            requestObserver = observer
        }


        override class func canInit(with request: URLRequest) -> Bool {

            requestObserver?(request)
            return true
        }


        override class func canonicalRequest(for request: URLRequest) -> URLRequest {

            return request
        }


        override func startLoading() {

            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }

            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }

            client?.urlProtocolDidFinishLoading(self)
        }


        override func stopLoading() {}
    }
}
