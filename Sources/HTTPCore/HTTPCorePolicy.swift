//
//  HTTPCorePolicy.swift
//  HTTPCore
//
//  Created by vsmbd on 07/02/26.
//

import Foundation

// MARK: - HTTPCorePolicy

/// Policy for redaction and optional metrics when emitting HTTP lifecycle events. Injected into clients; default is safe (no sensitive data in telemetry).
public struct HTTPCorePolicy: Sendable,
							  Hashable,
							  Encodable {
	// MARK: + Public scope

	/// When true, event payloads may include query parameters in URLs.
	public var allowQueryParametersInTelemetry: Bool
	/// When true, event payloads may include raw request/response byte counts (best-effort, not sensitive).
	public var includeByteCountsInTelemetry: Bool

	public init(
		allowQueryParametersInTelemetry: Bool = true,
		includeByteCountsInTelemetry: Bool = true
	) {
		self.allowQueryParametersInTelemetry = allowQueryParametersInTelemetry
		self.includeByteCountsInTelemetry = includeByteCountsInTelemetry
	}
}
