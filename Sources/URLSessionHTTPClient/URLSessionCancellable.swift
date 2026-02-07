//
//  URLSessionCancellable.swift
//  URLSessionHTTPClient
//
//  Created by vsmbd on 07/02/26.
//

import Foundation
import HTTPCore

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - URLSessionCancellable

/// Cancellable handle that wraps a URLSessionTask.
/// Thread-safe; supports cancel before the task is set (e.g. when execution is scheduled on a queue).
final class URLSessionCancellable: @unchecked Sendable,
								   Cancellable {
	// MARK: + Private scope

	private let lock: NSLock = .init()
	private var sessionTask: URLSessionTask?
	private var cancelled: Bool = false

	// MARK: + Default scope

	/// Sets the underlying task. Call from the execution queue after creating the task. If cancel was already called, cancels the task immediately.
	func setTask(_ task: URLSessionTask) {
		lock.lock()
		sessionTask = task
		let alreadyCancelled = cancelled
		lock.unlock()

		if alreadyCancelled {
			task.cancel()
		}
	}

	init() {
		lock.lock()
		defer {
			lock.unlock()
		}
	}

	func cancel() {
		lock.lock()
		cancelled = true
		let task = sessionTask
		lock.unlock()

		task?.cancel()
	}
}
