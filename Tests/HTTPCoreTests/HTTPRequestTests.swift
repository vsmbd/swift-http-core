//
//  HTTPRequestTests.swift
//  HTTPCoreTests
//
//  Created by vsmbd on 07/02/26.
//

import Foundation
import HTTPCore
import Testing

@Suite("HTTPRequest")
struct HTTPRequestTests {
	@Test("init assigns method, url, headers, body, timeout")
	func initAssignsProperties() throws {
		let url = URL(string: "https://example.com/path")!
		let headers = HTTPHeaders(["Accept": "application/json"])
		let body = Data("test".utf8)
		let timeout: TimeInterval = 10

		let request = HTTPRequest(
			method: .post,
			url: url,
			headers: headers,
			body: body,
			timeout: timeout
		)

		#expect(request.method == .post)
		#expect(request.url == url)
		#expect(request.headers.value(for: "Accept") == "application/json")
		#expect(request.body == body)
		#expect(request.timeout == timeout)
		#expect(request.requestID > 0)
	}

	@Test("init with defaults uses empty headers, nil body, nil timeout")
	func initDefaults() throws {
		let url = URL(string: "https://example.com")!
		let request = HTTPRequest(method: .get, url: url)

		#expect(request.headers.count == 0)
		#expect(request.body == nil)
		#expect(request.timeout == nil)
		#expect(request.requestID > 0)
	}

	@Test("requestID is unique across requests")
	func requestIDUnique() throws {
		let url = URL(string: "https://example.com")!
		let a = HTTPRequest(method: .get, url: url)
		let b = HTTPRequest(method: .get, url: url)
		#expect(a.requestID != b.requestID)
	}

	@Test("Encodable encodes without throwing")
	func encodableEncodes() throws {
		let url = URL(string: "https://example.com/api")!
		let request = HTTPRequest(
			method: .put,
			url: url,
			headers: HTTPHeaders(["X-Custom": "value"]),
			body: Data([1, 2, 3]),
			timeout: 5
		)
		let data = try JSONEncoder().encode(request)
		#expect(!data.isEmpty)
	}
}
