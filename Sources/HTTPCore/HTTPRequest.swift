//
//  HTTPRequest.swift
//  HTTPCore
//
//  Created by vsmbd on 07/02/26.
//

import Foundation
import HTTPCoreNativeCounters
import SwiftCore

// MARK: - HTTPRequest

/// Transport-agnostic HTTP request. Bodies are raw bytes at the contract boundary.
public struct HTTPRequest: Sendable,
						   Encodable,
						   Entity {
	// MARK: + Public scope

	public let identifier: UInt64
	public let requestID: UInt64
	public let method: HTTPMethod
	public let url: URL
	public var headers: HTTPHeaders
	public var body: Data?
	public var timeout: TimeInterval?

	public init(
		method: HTTPMethod,
		url: URL,
		headers: HTTPHeaders = .init(),
		body: Data? = nil,
		timeout: TimeInterval? = nil
	) {
		self.identifier = Self.nextID
		self.requestID = nextRequestID()
		self.method = method
		self.url = url
		self.headers = headers
		self.body = body
		self.timeout = timeout
	}
}
