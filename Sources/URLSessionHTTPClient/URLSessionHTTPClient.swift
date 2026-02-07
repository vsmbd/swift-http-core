//
//  URLSessionHTTPClient.swift
//  URLSessionHTTPClient
//
//  Created by vsmbd on 07/02/26.
//

import Foundation
import HTTPCore
import SwiftCore
import EventDispatch

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - URLSessionHTTPClient

/// URLSession-based implementation of `HTTPClient`.
/// Schedules execution on a `ConcurrentTaskQueue` (e.g. `TaskQueue.background`),
/// emits lifecycle events via `EventDispatcher`, and invokes completion on a configurable queue.
public final class URLSessionHTTPClient: HTTPClient,
										 Entity {
	// MARK: + Private scope

	private let session: URLSession
	private let policy: HTTPCorePolicy
	private let dispatcher: any EventDispatcher
	private let queue: ConcurrentTaskQueue
	private let completionQueue: ConcurrentTaskQueue

	// MARK: + Public scope

	public let identifier: UInt64

	public init(
		session: URLSession,
		policy: HTTPCorePolicy = .init(),
		dispatcher: any EventDispatcher = EventDispatch.default,
		queue: ConcurrentTaskQueue = TaskQueue.background,
		completionQueue: ConcurrentTaskQueue = TaskQueue.background
	) {
		self.identifier = Self.nextID

		self.session = session
		self.policy = policy
		self.dispatcher = dispatcher
		self.queue = queue
		self.completionQueue = completionQueue
	}

	@discardableResult
	public func execute(
		_ request: HTTPRequest,
		_ checkpoint: Checkpoint,
		completion: @escaping HTTPExecutionCompletion
	) -> Cancellable {
		let cancellable = URLSessionCancellable()

		emitCreated(request: request, checkpoint: checkpoint)
		queue.async(checkpoint) { [weak self] taskInfo in
			guard let self else { return }
			self.runTask(
				request: request,
				startedCheckpoint: taskInfo.checkpoint.next(self),
				cancellable: cancellable,
				completion: completion
			)
		}

		return cancellable
	}
}

// MARK: - URLSessionHTTPClient + Execution

private extension URLSessionHTTPClient {
	func emitCreated(request: HTTPRequest, checkpoint: Checkpoint) {
		dispatcher.sink(
			HTTPProcessingEvent.created(
				request: request,
				timestamp: .now
			),
			checkpoint,
			extra: nil
		)
	}

	func runTask(
		request: HTTPRequest,
		startedCheckpoint: Checkpoint,
		cancellable: URLSessionCancellable,
		completion: @escaping HTTPExecutionCompletion
	) {
		dispatcher.sink(
			HTTPProcessingEvent.started(
				request: request,
				timestamp: .now
			),
			startedCheckpoint,
			extra: nil
		)

		let urlRequest = Self.makeURLRequest(from: request)
		let task = session.dataTask(with: urlRequest) { [weak self] data, response, error in
			guard let self else { return }
			completionQueue.async(startedCheckpoint) { [weak self] taskInfo in
				guard let self else { return }
				let deliveryCheckpoint = taskInfo.checkpoint.next(self)
				self.handleTaskResult(
					data: data,
					response: response,
					error: error,
					request: request,
					checkpoint: deliveryCheckpoint,
					completion: completion
				)
			}
		}

		cancellable.setTask(task)
		task.resume()
	}

	func handleTaskResult(
		data: Data?,
		response: URLResponse?,
		error: Error?,
		request: HTTPRequest,
		checkpoint: Checkpoint,
		completion: @escaping HTTPExecutionCompletion
	) {
		let timestamp = MonotonicNanostamp.now

		if let urlError = error as? URLError, urlError.code == .cancelled {
			deliverCancelled(
				request: request,
				checkpoint: checkpoint,
				timestamp: timestamp,
				completion: completion
			)
			return
		}

		if let error = error {
			deliverFailure(
				request: request,
				error: Self.mapToHTTPError(error),
				checkpoint: checkpoint,
				timestamp: timestamp,
				completion: completion
			)
			return
		}

		guard let httpURLResponse = response as? HTTPURLResponse else {
			deliverInvalidResponse(
				request: request,
				checkpoint: checkpoint,
				timestamp: timestamp,
				completion: completion
			)
			return
		}

		deliverSuccess(
			request: request,
			urlResponse: httpURLResponse,
			data: data ?? Data(),
			checkpoint: checkpoint,
			timestamp: timestamp,
			completion: completion
		)
	}

	func deliverCancelled(
		request: HTTPRequest,
		checkpoint: Checkpoint,
		timestamp: MonotonicNanostamp,
		completion: HTTPExecutionCompletion
	) {
		dispatcher.sink(
			HTTPProcessingEvent.cancelled(
				request: request,
				timestamp: timestamp
			),
			checkpoint,
			extra: nil
		)
		completion(.failure(ErrorInfo(
			error: HTTPError.cancelled,
			checkpoint,
			timestamp: timestamp
		)))
	}

	func deliverFailure(
		request: HTTPRequest,
		error: HTTPError,
		checkpoint: Checkpoint,
		timestamp: MonotonicNanostamp,
		completion: HTTPExecutionCompletion
	) {
		dispatcher.sink(
			HTTPProcessingEvent.failed(
				request: request,
				error: error,
				timestamp: timestamp
			),
			checkpoint,
			extra: nil
		)
		completion(.failure(ErrorInfo(
			error: error,
			checkpoint,
			timestamp: timestamp
		)))
	}

	func deliverInvalidResponse(
		request: HTTPRequest,
		checkpoint: Checkpoint,
		timestamp: MonotonicNanostamp,
		completion: HTTPExecutionCompletion
	) {
		let httpError = HTTPError.invalidResponse
		deliverFailure(
			request: request,
			error: httpError,
			checkpoint: checkpoint,
			timestamp: timestamp,
			completion: completion
		)
	}

	func deliverSuccess(
		request: HTTPRequest,
		urlResponse: HTTPURLResponse,
		data: Data,
		checkpoint: Checkpoint,
		timestamp: MonotonicNanostamp,
		completion: HTTPExecutionCompletion
	) {
		let httpResponse = HTTPResponse(
			request: request,
			statusCode: urlResponse.statusCode,
			headers: Self.makeHTTPHeaders(from: urlResponse),
			data: data
		)

		dispatcher.sink(
			HTTPProcessingEvent.responseReceived(
				request: request,
				response: httpResponse,
				timestamp: timestamp
			),
			checkpoint,
			extra: nil
		)
		dispatcher.sink(
			HTTPProcessingEvent.succeeded(
				request: request,
				response: httpResponse,
				timestamp: timestamp
			),
			checkpoint,
			extra: nil
		)
		completion(.success(httpResponse, checkpoint))
	}

	static func mapToHTTPError(_ error: Error) -> HTTPError {
		guard let urlError = error as? URLError else {
			return .transport(underlying: String(describing: error))
		}
		switch urlError.code {
		case .cancelled: return .cancelled
		case .timedOut: return .timeout
		default: return .transport(underlying: String(describing: error))
		}
	}
}

// MARK: - URLSessionHTTPClient + Helpers

private extension URLSessionHTTPClient {
	static func makeURLRequest(from request: HTTPRequest) -> URLRequest {
		var urlRequest = URLRequest(url: request.url)
		urlRequest.httpMethod = request.method.rawValue
		urlRequest.httpBody = request.body
		if let timeout = request.timeout {
			urlRequest.timeoutInterval = timeout
		}
		for (name, value) in request.headers.all {
			urlRequest.setValue(
				value,
				forHTTPHeaderField: name
			)
		}
		return urlRequest
	}

	static func makeHTTPHeaders(from response: HTTPURLResponse) -> HTTPHeaders {
		var storage: [String: String] = [:]
		for (key, value) in response.allHeaderFields {
			guard let name = key as? String,
				  let value = value as? String else { continue }
			storage[name] = value
		}
		return HTTPHeaders(storage)
	}
}
