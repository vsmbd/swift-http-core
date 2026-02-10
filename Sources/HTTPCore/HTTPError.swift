//
//  HTTPError.swift
//  HTTPCore
//
//  Created by vsmbd on 07/02/26.
//

import Foundation
import SwiftCore

// MARK: - HTTPError

/// Normalized HTTP error taxonomy.
public enum HTTPError: ErrorEntity {
	case cancelled
	case timeout
	case invalidResponse
	/// Underlying transport failure. The associated value is a stable description for logging and telemetry; do not rely on it for programmatic branching.
	case transport(underlying: String)
	/// JSON encoding, decoding, or parsing failed. The associated value is a stable description for logging and telemetry.
	case json(underlying: String)
}
