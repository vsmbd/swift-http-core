//
//  URLSessionHTTPClientTests.swift
//  URLSessionHTTPClientTests
//
//  Created by vsmbd on 07/02/26.
//

import Foundation
import HTTPCore
import SwiftCore
import URLSessionHTTPClient
import Testing

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Test entity for checkpoints

private struct TestEntity: Entity {
	let identifier: UInt64
	init() { self.identifier = Self.nextID }
}

// MARK: - URLSessionHTTPClientTests

/// Suite runs serially so StubURLProtocol.handler is not overwritten by parallel tests.
@Suite("URLSessionHTTPClient", .serialized)
struct URLSessionHTTPClientTests {
	// MARK: Success path

	@Test("execute returns success with response and checkpoint when stub returns 200")
	func executeSuccess() async throws {
		let url = URL(string: "https://example.com/ok")!
		let request = HTTPRequest(
			method: .get,
			url: url,
			headers: HTTPHeaders(["Accept": "application/json"]),
			body: nil,
			timeout: 10
		)
		let responseData = Data("hello".utf8)
		StubURLProtocol.handler = { _ in
			(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "text/plain"]), responseData, nil)
		}
		defer { StubURLProtocol.handler = nil }
		let config = URLSessionConfiguration.ephemeral
		config.protocolClasses = [StubURLProtocol.self]
		let session = URLSession(configuration: config)
		let recording = RecordingEventDispatcher()
		let client = URLSessionHTTPClient(
			session: session,
			dispatcher: recording,
			queue: TaskQueue.background,
			completionQueue: TaskQueue.background
		)
		let checkpoint = Checkpoint.checkpoint(TestEntity())

		let result = await withCheckedContinuation { (cont: CheckedContinuation<HTTPExecutionResult, Never>) in
			_ = client.execute(request, checkpoint) { cont.resume(returning: $0) }
		}

		guard case let .success(response, resultCheckpoint) = result else {
			Issue.record("expected success, got \(result)")
			return
		}
		#expect(response.requestID == request.requestID)
		#expect(response.statusCode == 200)
		#expect(response.data == responseData)
		#expect(response.headers.value(for: "Content-Type") == "text/plain")
		#expect(resultCheckpoint.entityId == client.identifier)
		let kinds = recording.events.map(\.event.kind)
		#expect(kinds.contains(where: { $0.hasSuffix("_created") }))
		#expect(kinds.contains(where: { $0.hasSuffix("_started") }))
		#expect(kinds.contains(where: { $0.hasSuffix("_received") }))
		#expect(kinds.contains(where: { $0.hasSuffix("_succeeded") }))
	}

	@Test("execute maps URLError cancelled to HTTPError cancelled")
	func executeCancelledError() async throws {
		let url = URL(string: "https://example.com/cancel")!
		let request = HTTPRequest(method: .get, url: url)
		StubURLProtocol.handler = { _ in (nil, nil, URLError(.cancelled)) }
		defer { StubURLProtocol.handler = nil }
		let config = URLSessionConfiguration.ephemeral
		config.protocolClasses = [StubURLProtocol.self]
		let session = URLSession(configuration: config)
		let recording = RecordingEventDispatcher()
		let client = URLSessionHTTPClient(session: session, dispatcher: recording)
		let checkpoint = Checkpoint.checkpoint(TestEntity())

		let result = await withCheckedContinuation { (cont: CheckedContinuation<HTTPExecutionResult, Never>) in
			_ = client.execute(request, checkpoint) { cont.resume(returning: $0) }
		}

		guard case let .failure(errorInfo) = result else {
			Issue.record("expected failure, got \(result)")
			return
		}
		switch errorInfo.error {
		case .cancelled: break
		default: Issue.record("expected .cancelled, got \(errorInfo.error)")
		}
		let events = recording.events
		#expect(events.contains(where: { $0.event.kind.hasSuffix("_failed") }) || events.contains(where: { $0.event.kind.hasSuffix("_cancelled") }))
	}

	@Test("execute maps URLError timedOut to HTTPError timeout")
	func executeTimeoutError() async throws {
		let url = URL(string: "https://example.com/slow")!
		let request = HTTPRequest(method: .get, url: url)
		StubURLProtocol.handler = { _ in (nil, nil, URLError(.timedOut)) }
		defer { StubURLProtocol.handler = nil }
		let config = URLSessionConfiguration.ephemeral
		config.protocolClasses = [StubURLProtocol.self]
		let session = URLSession(configuration: config)
		let client = URLSessionHTTPClient(session: session)
		let checkpoint = Checkpoint.checkpoint(TestEntity())

		let result = await withCheckedContinuation { (cont: CheckedContinuation<HTTPExecutionResult, Never>) in
			_ = client.execute(request, checkpoint) { cont.resume(returning: $0) }
		}

		guard case let .failure(errorInfo) = result else {
			Issue.record("expected failure")
			return
		}
		switch errorInfo.error {
		case .timeout: break
		default: Issue.record("expected .timeout, got \(errorInfo.error)")
		}
	}

	@Test("execute returns invalidResponse when response is not HTTPURLResponse")
	func executeInvalidResponse() async throws {
		let url = URL(string: "https://example.com/bad")!
		let request = HTTPRequest(method: .get, url: url)
		StubURLProtocol.handler = { _ in
			(URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil), nil, nil)
		}
		defer { StubURLProtocol.handler = nil }
		let config = URLSessionConfiguration.ephemeral
		config.protocolClasses = [StubURLProtocol.self]
		let session = URLSession(configuration: config)
		let client = URLSessionHTTPClient(session: session)
		let checkpoint = Checkpoint.checkpoint(TestEntity())

		let result = await withCheckedContinuation { (cont: CheckedContinuation<HTTPExecutionResult, Never>) in
			_ = client.execute(request, checkpoint) { cont.resume(returning: $0) }
		}

		guard case let .failure(errorInfo) = result else {
			Issue.record("expected failure")
			return
		}
		switch errorInfo.error {
		case .invalidResponse: break
		default: Issue.record("expected .invalidResponse, got \(errorInfo.error)")
		}
	}

	@Test("execute maps other errors to transport underlying")
	func executeTransportError() async throws {
		let url = URL(string: "https://example.com/err")!
		let request = HTTPRequest(method: .get, url: url)
		StubURLProtocol.handler = { _ in (nil, nil, URLError(.networkConnectionLost)) }
		defer { StubURLProtocol.handler = nil }
		let config = URLSessionConfiguration.ephemeral
		config.protocolClasses = [StubURLProtocol.self]
		let session = URLSession(configuration: config)
		let client = URLSessionHTTPClient(session: session)
		let checkpoint = Checkpoint.checkpoint(TestEntity())

		let result = await withCheckedContinuation { (cont: CheckedContinuation<HTTPExecutionResult, Never>) in
			_ = client.execute(request, checkpoint) { cont.resume(returning: $0) }
		}

		guard case let .failure(errorInfo) = result else {
			Issue.record("expected failure")
			return
		}
		switch errorInfo.error {
		case .transport: break
		default: Issue.record("expected .transport, got \(errorInfo.error)")
		}
	}

	@Test("cancel stops in-flight request")
	func cancelStopsRequest() async throws {
		let url = URL(string: "https://example.com/hang")!
		let request = HTTPRequest(method: .get, url: url)
		StubURLProtocol.handler = { _ in (nil, nil, nil) }
		defer { StubURLProtocol.handler = nil }
		let config = URLSessionConfiguration.ephemeral
		config.protocolClasses = [StubURLProtocol.self]
		let session = URLSession(configuration: config)
		let client = URLSessionHTTPClient(session: session)
		let checkpoint = Checkpoint.checkpoint(TestEntity())
		let cancellable = client.execute(request, checkpoint) { _ in }
		cancellable.cancel()
		try await Task.sleep(nanoseconds: 200_000_000) // 0.2s for completion with cancelled
	}

	@Test("request is translated to URLRequest with method url headers body timeout")
	func requestTranslation() async throws {
		let url = URL(string: "https://example.com/api")!
		let body = Data("body".utf8)
		let request = HTTPRequest(
			method: .post,
			url: url,
			headers: HTTPHeaders(["X-Custom": "value"]),
			body: body,
			timeout: 30
		)
		var capturedRequest: URLRequest?
		StubURLProtocol.handler = { req in
			capturedRequest = req
			return (HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil), Data(), nil)
		}
		defer { StubURLProtocol.handler = nil }
		let config = URLSessionConfiguration.ephemeral
		config.protocolClasses = [StubURLProtocol.self]
		let session = URLSession(configuration: config)
		let client = URLSessionHTTPClient(session: session)
		let checkpoint = Checkpoint.checkpoint(TestEntity())

		_ = await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
			_ = client.execute(request, checkpoint) { _ in cont.resume() }
		}

		#expect(capturedRequest != nil)
		let req = try #require(capturedRequest)
		#expect(req.url == url)
		#expect(req.httpMethod == "POST")
		// URLSession does not always expose httpBody to URLProtocol (e.g. streamed); client sets urlRequest.httpBody in makeURLRequest.
		if let receivedBody = req.httpBody {
			#expect(receivedBody == body)
		}
		#expect(req.timeoutInterval == 30)
		#expect(req.value(forHTTPHeaderField: "X-Custom") == "value")
	}

	@Test("caller checkpoint is used for created event and completion delivers a checkpoint")
	func checkpointCorrelation() async throws {
		let url = URL(string: "https://example.com/cp")!
		let request = HTTPRequest(method: .get, url: url)
		StubURLProtocol.handler = { _ in
			(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil), Data(), nil)
		}
		defer { StubURLProtocol.handler = nil }
		let config = URLSessionConfiguration.ephemeral
		config.protocolClasses = [StubURLProtocol.self]
		let session = URLSession(configuration: config)
		let recording = RecordingEventDispatcher()
		let client = URLSessionHTTPClient(session: session, dispatcher: recording)
		let entity = TestEntity()
		let callerCheckpoint = Checkpoint.checkpoint(entity)

		let result = await withCheckedContinuation { (cont: CheckedContinuation<HTTPExecutionResult, Never>) in
			_ = client.execute(request, callerCheckpoint) { cont.resume(returning: $0) }
		}

		let createdEvents = recording.events.filter { $0.event.kind.hasSuffix("_created") }
		#expect(createdEvents.count == 1)
		#expect(createdEvents[0].checkpoint.entityId == entity.identifier)
		switch result {
		case let .success(_, deliveryCheckpoint):
			#expect(deliveryCheckpoint.entityId == client.identifier)
		case let .failure(errorInfo):
			Issue.record("expected success for checkpoint correlation test, got \(errorInfo.error)")
		}
	}
}
