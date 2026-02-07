//
//  HTTPMethod.swift
//  HTTPCore
//
//  Created by vsmbd on 07/02/26.
//

import Foundation

// MARK: - HTTPMethod

/// HTTP method.
public enum HTTPMethod: String,
						Sendable,
						Hashable,
						Encodable,
						CaseIterable {
	case get = "GET"
	case post = "POST"
	case put = "PUT"
	case delete = "DELETE"
	case patch = "PATCH"
	case head = "HEAD"
	case options = "OPTIONS"
}
