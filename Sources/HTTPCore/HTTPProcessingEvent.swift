//
//  HTTPProcessingEvent.swift
//  HTTPCore
//
//  Created by vsmbd on 07/02/26.
//

import EventDispatch
import Foundation
import SwiftCore

// MARK: - HTTPProcessingEvent

/// Enum for all HTTP request lifecycle phases and states.
/// Conforms to Event for EventDispatch.
public enum HTTPProcessingEvent: Sendable {
	case created(
		request: HTTPRequest,
		timestamp: MonotonicNanostamp = .now
	)
	case started(
		request: HTTPRequest,
		timestamp: MonotonicNanostamp = .now
	)
	case responseReceived(
		request: HTTPRequest,
		response: HTTPResponse,
		timestamp: MonotonicNanostamp = .now
	)
	case succeeded(
		request: HTTPRequest,
		response: HTTPResponse,
		timestamp: MonotonicNanostamp = .now
	)
	case failed(
		request: HTTPRequest,
		error: HTTPError,
		timestamp: MonotonicNanostamp = .now
	)
	case cancelled(
		request: HTTPRequest,
		timestamp: MonotonicNanostamp = .now
	)
}

// MARK: - HTTPProcessingEvent + Event

extension HTTPProcessingEvent: Event {
	// MARK: + Public scope

	public var kind: String {
		switch self {
		case .created:
			return typeName + "_created"
		case .started:
			return typeName + "_started"

		case .responseReceived:
			return typeName + "_received"

		case .succeeded:
			return typeName + "_succeeded"

		case .failed:
			return typeName + "_failed"

		case .cancelled:
			return typeName + "_cancelled"
		}
	}
}
