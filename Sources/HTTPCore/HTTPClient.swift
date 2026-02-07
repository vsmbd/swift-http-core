//
//  HTTPClient.swift
//  HTTPCore
//
//  Created by vsmbd on 07/02/26.
//

import Foundation
import SwiftCore

// MARK: - Cancellable

/// Handle to cancel an in-flight request. Implementations must be thread-safe.
public protocol Cancellable: Sendable {
	func cancel()
}

// MARK: - HTTPClient

/// Result type for HTTP execution: checkpointed success (response + checkpoint) or failure (error info).
public typealias HTTPExecutionResult = CheckpointedResult<
	HTTPResponse,
	HTTPError
>

/// Completion handler for HTTP execution; receives a checkpointed result.
public typealias HTTPExecutionCompletion = @Sendable (HTTPExecutionResult) -> Void

/// Transport-agnostic HTTP client. Implementations must schedule work on an explicit queue (e.g. `TaskQueue.background`) and invoke completion on the documented queue.
public protocol HTTPClient: Sendable {
	/// Executes the request. Completion is invoked on the queue documented by the implementation (e.g. caller-provided or background).
	@discardableResult
	func execute(
		_ request: HTTPRequest,
		completion: @escaping HTTPExecutionCompletion
	) -> Cancellable
}
