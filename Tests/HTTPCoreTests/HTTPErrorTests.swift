//
//  HTTPErrorTests.swift
//  HTTPCoreTests
//
//  Created by vsmbd on 07/02/26.
//

import Foundation
import HTTPCore
import SwiftCore
import Testing

@Suite("HTTPError")
struct HTTPErrorTests {
	@Test("cases are distinct")
	func casesDistinct() {
		let cancelled: HTTPError = .cancelled
		let timeout: HTTPError = .timeout
		let invalid: HTTPError = .invalidResponse
		#expect(equatable(cancelled, timeout) == false)
		#expect(equatable(timeout, invalid) == false)
	}

	private func equatable(_ a: HTTPError, _ b: HTTPError) -> Bool {
		switch (a, b) {
		case (.cancelled, .cancelled), (.timeout, .timeout), (.invalidResponse, .invalidResponse):
			return true
		case let (.transport(x), .transport(y)): return x == y
		default: return false
		}
	}

	@Test("transport carries underlying description")
	func transportUnderlying() {
		let err = HTTPError.transport(underlying: "Connection refused")
		switch err {
		case .transport(let underlying):
			#expect(underlying == "Connection refused")
		default:
			Issue.record("expected transport case")
		}
	}

	@Test("Encodable encodes all cases")
	func encodableEncodes() throws {
		let cases: [HTTPError] = [
			.cancelled,
			.timeout,
			.invalidResponse,
			.transport(underlying: "test")
		]
		for error in cases {
			let data = try JSONEncoder().encode(error)
			#expect(!data.isEmpty)
		}
	}
}
