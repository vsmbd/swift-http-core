//
//  HTTPResponse+JSON.swift
//  HTTPCore
//
//  Created by vsmbd on 07/02/26.
//

import Foundation
import JSON
import SwiftCore

// MARK: - HTTPResponse + JSON

/// Result type for response JSON operations: checkpointed success or failure with `HTTPError`.
public typealias HTTPResponseJSONResult<T> = CheckpointedResult<T, HTTPError>

extension HTTPResponse {

	/// Parses the response body (`data`) as JSON into a swift-json `JSON` value.
	///
	/// - Returns: `.success(JSON, checkpoint)` or `.failure(ErrorInfo<HTTPError>)`.
	public func json() -> HTTPResponseJSONResult<JSON> {
		let checkpoint = Checkpoint.checkpoint(self)
		do {
			let value = try JSON.parse(data)
			return .success(value, checkpoint)
		} catch {
			return .failure(ErrorInfo(
				error: .json(underlying: String(describing: error)),
				checkpoint
			))
		}
	}

	/// Decodes the response body as JSON into the given type (via swift-json).
	///
	/// - Parameters:
	///   - type: Decodable type to decode.
	///   - decoder: Decoder to use for JSON → type.
	/// - Returns: `.success(T, checkpoint)` or `.failure(ErrorInfo<HTTPError>)`.
	public func decoded<T: Decodable & Sendable>(
		as type: T.Type,
		decoder: JSONDecoder = .init()
	) -> HTTPResponseJSONResult<T> {
		switch json() {
		case let .success(jsonValue, checkpoint):
			do {
				let value = try jsonValue.decode(type, decoder: decoder)
				return .success(value, checkpoint)
			} catch {
				return .failure(ErrorInfo(
					error: .json(underlying: String(describing: error)),
					checkpoint
				))
			}
		case let .failure(errorInfo):
			return .failure(errorInfo)
		}
	}
}
