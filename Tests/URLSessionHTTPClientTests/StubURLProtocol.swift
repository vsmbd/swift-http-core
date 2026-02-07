//
//  StubURLProtocol.swift
//  URLSessionHTTPClientTests
//
//  Created by vsmbd on 07/02/26.
//

import Foundation

/// URLProtocol stub that returns a configured response, data, or error.
/// Configure via `StubURLProtocol.handler` before creating the URLSession.
final class StubURLProtocol: URLProtocol {
	override class func canInit(with request: URLRequest) -> Bool {
		true
	}

	override class func canonicalRequest(for request: URLRequest) -> URLRequest {
		request
	}

	override func startLoading() {
		guard let handler = Self.handler else {
			client?.urlProtocol(
				self,
				didFailWithError: NSError(
					domain: "StubURLProtocol",
					code: -1,
					userInfo: [NSLocalizedDescriptionKey: "No handler set"]
				)
			)
			return
		}
		let (response, data, error) = handler(request)
		// All nil = hang (no callbacks); task can be cancelled.
		if response == nil, data == nil, error == nil {
			return
		}
		if let error {
			client?.urlProtocol(
				self,
				didFailWithError: error
			)
			return
		}
		if let response {
			client?.urlProtocol(
				self,
				didReceive: response,
				cacheStoragePolicy: .notAllowed
			)
		}
		if let data {
			client?.urlProtocol(
				self,
				didLoad: data
			)
		}
		client?.urlProtocolDidFinishLoading(self)
	}

	override func stopLoading() {
		//
	}

	/// Per-request handler: (URLRequest) -> (URLResponse?, Data?, Error?). Set before each test; cleared in tearDown. Tests run sequentially so this is not shared across concurrent work.
	nonisolated(unsafe) static var handler: ((URLRequest) -> (
		URLResponse?,
		Data?,
		Error?
	))?
}
