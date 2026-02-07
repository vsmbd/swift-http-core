//
//  HTTPResponseTests.swift
//  HTTPCoreTests
//
//  Created by vsmbd on 07/02/26.
//

import Foundation
import HTTPCore
import Testing

@Suite("HTTPResponse")
struct HTTPResponseTests {
	@Test("init derives requestID from request")
	func initDerivesRequestID() throws {
		let url = URL(string: "https://example.com")!
		let request = HTTPRequest(method: .get, url: url)
		let headers = HTTPHeaders(["Content-Type": "text/plain"])
		let body = Data("ok".utf8)

		let response = HTTPResponse(
			request: request,
			statusCode: 200,
			headers: headers,
			data: body
		)

		#expect(response.requestID == request.requestID)
		#expect(response.statusCode == 200)
		#expect(response.headers.value(for: "Content-Type") == "text/plain")
		#expect(response.data == body)
	}

	@Test("Encodable encodes without throwing")
	func encodableEncodes() throws {
		let url = URL(string: "https://example.com")!
		let request = HTTPRequest(method: .get, url: url)
		let response = HTTPResponse(
			request: request,
			statusCode: 201,
			headers: HTTPHeaders(["Location": "/resource/1"]),
			data: Data("created".utf8)
		)
		let data = try JSONEncoder().encode(response)
		#expect(!data.isEmpty)
	}
}
