//
//  HTTPHeadersTests.swift
//  HTTPCoreTests
//
//  Created by vsmbd on 07/02/26.
//

import Foundation
import HTTPCore
import Testing

@Suite("HTTPHeaders")
struct HTTPHeadersTests {
	@Test("init from dictionary stores values")
	func initFromDictionary() {
		let headers = HTTPHeaders(["Accept": "application/json", "Content-Type": "text/plain"])
		#expect(headers.count == 2)
		#expect(headers.value(for: "Accept") == "application/json")
		#expect(headers.value(for: "Content-Type") == "text/plain")
	}

	@Test("value(for:) returns nil for missing key")
	func valueForMissingReturnsNil() {
		let headers = HTTPHeaders()
		#expect(headers.value(for: "Missing") == nil)
	}

	@Test("setValue adds and updates")
	func setValueAddsAndUpdates() {
		var headers = HTTPHeaders()
		headers.setValue("first", for: "X-Header")
		#expect(headers.value(for: "X-Header") == "first")
		headers.setValue("second", for: "X-Header")
		#expect(headers.value(for: "X-Header") == "second")
	}

	@Test("setValue nil removes key")
	func setValueNilRemoves() {
		var headers = HTTPHeaders(["X-Header": "value"])
		headers.setValue(nil, for: "X-Header")
		#expect(headers.value(for: "X-Header") == nil)
		#expect(headers.count == 0)
	}

	@Test("all returns storage copy")
	func allReturnsStorage() {
		let dict = ["A": "1", "B": "2"]
		let headers = HTTPHeaders(dict)
		#expect(headers.all == dict)
	}

	@Test("ExpressibleByDictionaryLiteral")
	func dictionaryLiteral() {
		let headers: HTTPHeaders = ["Key": "Value", "Other": "Val"]
		#expect(headers.count == 2)
		#expect(headers.value(for: "Key") == "Value")
		#expect(headers.value(for: "Other") == "Val")
	}

	@Test("keys are case-sensitive")
	func caseSensitive() {
		let headers = HTTPHeaders(["Accept": "json"])
		#expect(headers.value(for: "Accept") == "json")
		#expect(headers.value(for: "accept") == nil)
	}
}
