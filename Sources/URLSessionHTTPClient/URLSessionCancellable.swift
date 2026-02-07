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

/// Cancellable handle that wraps a URLSessionTask. Thread-safe; supports cancel before the task is set (e.g. when execution is scheduled on a queue).
final class URLSessionCancellable: @unchecked Sendable,
								   Cancellable {
	// MARK: + Private scope

	private let lock: NSLock = .init()
	private var _task: URLSessionTask?
	private var _cancelled: Bool = false

	// MARK: + Default scope

	/// Sets the underlying task. Call from the execution queue after creating the task. If cancel was already called, cancels the task immediately.
	func setTask(_ task: URLSessionTask) {
		lock.lock()
		_task = task
		let alreadyCancelled = _cancelled
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
		_cancelled = true
		let task = _task
		lock.unlock()

		task?.cancel()
	}
}
