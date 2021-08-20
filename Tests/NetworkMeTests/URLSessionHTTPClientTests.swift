//
//  URLSessionHTTPClientTests.swift
//  
//
//  Created by Boyce Estes on 8/14/21.
//

import Foundation
import XCTest
import NetworkMe


class URLSessionHTTPClient: HTTPClient {

    let session: URLSession


    init(session: URLSession = .shared) {
        self.session = session
    }

    struct UnexpectedValuesRepresentation: Error {}

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in

            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
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
        let error = anyNSError()

        let receivedError = resultErrorFor(data: nil, response: nil, error: error) as NSError?

        XCTAssertEqual(receivedError?.domain, error.domain)
        XCTAssertEqual(receivedError?.code, error.code)
    }


    func test_URLSessionHTTPClient_getFromURL_failsOnAllInvalidRepresentationCases() {

        // If we were not it is possible they could return some other error, should possibly compare if it is
        // UnexpectedValuesRepresentation
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    }


    func test_URLSessionHTTPClient_getFromURL_succeedsOnHTTPURLResponseWithData() {

        let data = anyData()
        let response = anyHTTPURLResponse()

        let receivedValues = resultValuesFor(data: data, response: response, error: nil)

        XCTAssertEqual(receivedValues?.data, data)
        XCTAssertEqual(receivedValues?.response.url, response?.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response?.statusCode)
    }


    func test_URLSessionHTTPClient_getFromURL_succeedsWithEmptyDataOnHTTPURLResponseWithNilData() {

        let response = anyHTTPURLResponse()

        let receivedValues = resultValuesFor(data: nil, response: response, error: nil)

        let emptyData = Data()
        XCTAssertEqual(receivedValues?.data, emptyData)
        XCTAssertEqual(receivedValues?.response.url, response?.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response?.statusCode)
    }


    // MARK: - Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> HTTPClient {

        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }


    private func resultValuesFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {

        let result = resultsFor(data: data, response: response, error: error, file: file, line: line)

        switch result {
        case .success(let data, let response):
            return (data, response)
        default:
            XCTFail("Expected success, got \(result) instead", file: file, line: line)
            return nil
        }
    }


    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Error? {

        let result = resultsFor(data: data, response: response, error: error, file: file, line: line)

        switch result {
        case .failure(let error):
            return error
        default:
            XCTFail("Expected failure, got \(result) instead", file: file, line: line)
            return nil
        }
    }


    private func resultsFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> HTTPClientResult {

        URLProtocolStub.stub(data: data, response: response, error: error)

        let sut = makeSUT(file: file, line: line)
        let exp = expectation(description: "Wait for completion")
        var receivedResult: HTTPClientResult!

        sut.get(from: anyURL()) { result in
            receivedResult = result

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }


    private func anyURL() -> URL {

        return URL(string: "https://any-url.com")!
    }


    private func anyData() -> Data {

        return Data(bytes: "any data", count: "any data".count)
    }


    private func anyNSError() -> NSError {

        return NSError(domain: "any error", code: 0)
    }


    private func anyHTTPURLResponse() -> HTTPURLResponse? {

        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)
    }


    private func nonHTTPURLResponse() -> URLResponse? {

        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
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
