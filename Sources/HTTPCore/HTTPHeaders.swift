//
//  HTTPHeaders.swift
//  HTTPCore
//
//  Created by vsmbd on 07/02/26.
//

import Foundation

// MARK: - HTTPHeaders

/// HTTP headers: single value per name. Keys are stored as given (case-sensitive). Backed by a dictionary.
public struct HTTPHeaders: Sendable,
						   Hashable,
						   Encodable {
	// MARK: + Private scope

	private var storage: Storage

	// MARK: + Public scope

	public typealias Storage = [String: String]

	/// Creates headers from a dictionary.
	public init(_ dictionary: [String: String] = [:]) {
		storage = dictionary.reduce(into: [:]) { acc, pair in
			acc[pair.key] = pair.value
		}
	}

	/// Returns the value for the header name.
	public func value(for name: String) -> String? {
		storage[name]
	}

	/// Sets the value for the header name.
	public mutating func setValue(
		_ value: String?,
		for key: String
	) {
		if let value {
			storage[key] = value
		} else {
			storage.removeValue(forKey: key)
		}
	}

	/// All header names and values.
	public var all: Storage {
		storage
	}

	/// Number of headers.
	public var count: Int {
		storage.count
	}
}

// MARK: - HTTPHeaders + ExpressibleByDictionaryLiteral

extension HTTPHeaders: ExpressibleByDictionaryLiteral {
	public init(dictionaryLiteral elements: (String, String)...) {
		self.init(Dictionary(uniqueKeysWithValues: elements))
	}
}
