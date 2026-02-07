//
//  HTTPProcessingEventTests.swift
//  HTTPCoreTests
//
//  Created by vsmbd on 07/02/26.
//

import Foundation
import HTTPCore
import SwiftCore
import Testing

@Suite("HTTPProcessingEvent")
struct HTTPProcessingEventTests {
	@Test("kind suffixes match phase names")
	func kindSuffixes() {
		let url = URL(string: "https://example.com")!
		let request = HTTPRequest(method: .get, url: url)
		let headers = HTTPHeaders()
		let response = HTTPResponse(request: request, statusCode: 200, headers: headers, data: Data())

		#expect(HTTPProcessingEvent.created(request: request, timestamp: .now).kind.hasSuffix("_created"))
		#expect(HTTPProcessingEvent.started(request: request, timestamp: .now).kind.hasSuffix("_started"))
		#expect(HTTPProcessingEvent.responseReceived(request: request, response: response, timestamp: .now).kind.hasSuffix("_received"))
		#expect(HTTPProcessingEvent.succeeded(request: request, response: response, timestamp: .now).kind.hasSuffix("_succeeded"))
		#expect(HTTPProcessingEvent.failed(request: request, error: .cancelled, timestamp: .now).kind.hasSuffix("_failed"))
		#expect(HTTPProcessingEvent.cancelled(request: request, timestamp: .now).kind.hasSuffix("_cancelled"))
	}

	@Test("Event kind is non-empty")
	func kindNonEmpty() {
		let url = URL(string: "https://example.com")!
		let request = HTTPRequest(method: .get, url: url)
		let events: [HTTPProcessingEvent] = [
			.created(request: request, timestamp: .now),
			.started(request: request, timestamp: .now),
			.cancelled(request: request, timestamp: .now)
		]
		for event in events {
			#expect(!event.kind.isEmpty)
			#expect(event.kind.contains("HTTPProcessingEvent"))
		}
	}
}
