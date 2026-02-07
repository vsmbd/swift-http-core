//
//  HTTPExecutionResultTests.swift
//  HTTPCoreTests
//
//  Created by vsmbd on 07/02/26.
//

import Foundation
import HTTPCore
import SwiftCore
import Testing

private struct TestEntity: Entity {
	let identifier: UInt64
	init() { self.identifier = Self.nextID }
}

@Suite("HTTPExecutionResult")
struct HTTPExecutionResultTests {
	@Test("success carries response and checkpoint")
	func successCarriesResponseAndCheckpoint() {
		let url = URL(string: "https://example.com")!
		let request = HTTPRequest(method: .get, url: url)
		let response = HTTPResponse(
			request: request,
			statusCode: 200,
			headers: HTTPHeaders(),
			data: Data()
		)
		let entity = TestEntity()
		let checkpoint = Checkpoint.checkpoint(entity)
		let result: HTTPExecutionResult = .success(response, checkpoint)

		guard case let .success(r, c) = result else {
			Issue.record("expected success")
			return
		}
		#expect(r.requestID == request.requestID)
		#expect(r.statusCode == 200)
		#expect(c == checkpoint)
	}

	@Test("failure carries ErrorInfo with checkpoint")
	func failureCarriesErrorInfo() {
		let entity = TestEntity()
		let checkpoint = Checkpoint.checkpoint(entity)
		let errorInfo = ErrorInfo(error: HTTPError.timeout, checkpoint, timestamp: .now)
		let result: HTTPExecutionResult = .failure(errorInfo)

		guard case let .failure(info) = result else {
			Issue.record("expected failure")
			return
		}
		#expect(info.checkpoint == checkpoint)
		switch info.error {
		case .timeout: break
		default: Issue.record("expected timeout")
		}
	}
}
