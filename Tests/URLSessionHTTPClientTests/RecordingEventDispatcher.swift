//
//  RecordingEventDispatcher.swift
//  URLSessionHTTPClientTests
//
//  Created by vsmbd on 07/02/26.
//

import Foundation
import EventDispatch
import HTTPCore
import SwiftCore

/// EventDispatcher that records every sunk event and checkpoint synchronously for test assertions.
final class RecordingEventDispatcher: @unchecked Sendable,
									  EventDispatcher {
	private let lock = NSLock()

	private var wrappedEvents: [(
		event: HTTPProcessingEvent,
		checkpoint: Checkpoint
	)] = []

	func sink<E: Event>(
		_ event: E,
		_ checkpoint: Checkpoint,
		extra: [String: ScalarValue]?
	) {
		lock.lock()
		defer {
			lock.unlock()
		}

		if let httpEvent = event as? HTTPProcessingEvent {
			wrappedEvents.append((httpEvent, checkpoint))
		}
	}

	/// Recorded (event, checkpoint) pairs in order of sink calls. Thread-safe.
	var events: [(
		event: HTTPProcessingEvent,
		checkpoint: Checkpoint
	)] {
		lock.lock()
		defer {
			lock.unlock()
		}
		return wrappedEvents
	}

	func clear() {
		lock.lock()
		defer {
			lock.unlock()
		}
		wrappedEvents.removeAll()
	}
}
