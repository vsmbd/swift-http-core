//
//  HTTPRequest+JSON.swift
//  HTTPCore
//
//  Created by vsmbd on 07/02/26.
//

import Foundation
import JSON
import SwiftCore

// MARK: - HTTPRequest + JSON

/// Result type for request JSON operations: checkpointed success or failure with `HTTPError`.
public typealias HTTPRequestJSONResult<T> = CheckpointedResult<T, HTTPError>

extension HTTPRequest {
	/// Sets the request body to the serialized `JSON` value and sets `Content-Type: application/json`.
	/// Overwrites any existing body and Content-Type.
	///
	/// - Parameters:
	///   - json: swift-json `JSON` value to serialize.
	///   - prettyPrinted: If `true`, output is pretty-printed for readability.
	/// - Returns: `.success((), checkpoint)` or `.failure(ErrorInfo<HTTPError>)`.
	public mutating func setJSONBody(
		_ json: JSON,
		prettyPrinted: Bool = false
	) -> HTTPRequestJSONResult<Void> {
		let checkpoint = Checkpoint.checkpoint(self)
		do {
			body = try json.toData(prettyPrinted: prettyPrinted)
			headers.setValue("application/json", for: "Content-Type")
			return .success((), checkpoint)
		} catch {
			return .failure(ErrorInfo(
				error: .json(underlying: String(describing: error)),
				checkpoint
			))
		}
	}

	/// Sets the request body to the JSON-encoded value (via swift-json) and sets `Content-Type: application/json`.
	///
	/// - Parameters:
	///   - value: Encodable value to encode to `JSON` then serialize.
	///   - encoder: Encoder to use for Encodable → intermediate data.
	/// - Returns: `.success((), checkpoint)` or `.failure(ErrorInfo<HTTPError>)`.
	public mutating func setJSONBody<T: Encodable & Sendable>(
		_ value: T,
		encoder: JSONEncoder = .init()
	) -> HTTPRequestJSONResult<Void> {
		let checkpoint = Checkpoint.checkpoint(self)
		do {
			let json = try JSON.encode(value, encoder: encoder)
			return setJSONBody(json, prettyPrinted: false)
		} catch {
			return .failure(ErrorInfo(
				error: .json(underlying: String(describing: error)),
				checkpoint
			))
		}
	}

	/// Parses the request body as JSON into a swift-json `JSON` value.
	///
	/// - Returns: `.success(JSON?, checkpoint)` (nil when body is nil or empty) or `.failure(ErrorInfo<HTTPError>)`.
	public func jsonBody() -> HTTPRequestJSONResult<JSON?> {
		let checkpoint = Checkpoint.checkpoint(self)
		guard let body,
			  body.isEmpty == false else {
			return .success(nil, checkpoint)
		}

		do {
			let json = try JSON.parse(body)
			return .success(json, checkpoint)
		} catch {
			return .failure(ErrorInfo(
				error: .json(underlying: String(describing: error)),
				checkpoint
			))
		}
	}

	/// Decodes the request body as JSON into the given type (via swift-json).
	///
	/// - Parameters:
	///   - type: Decodable type to decode.
	///   - decoder: Decoder to use for JSON → type.
	/// - Returns: `.success(T?, checkpoint)` (nil when body is nil or empty) or `.failure(ErrorInfo<HTTPError>)`.
	public func jsonBody<T: Decodable & Sendable>(
		as type: T.Type,
		decoder: JSONDecoder = .init()
	) -> HTTPRequestJSONResult<T?> {
		switch jsonBody() {
		case let .success(optJson, checkpoint):
			guard let json = optJson else {
				return .success(nil, checkpoint)
			}

			do {
				let value = try json.decode(type, decoder: decoder)
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
