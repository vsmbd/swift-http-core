//
//  HTTPResponse.swift
//  HTTPCore
//
//  Created by vsmbd on 07/02/26.
//

import Foundation

// MARK: - HTTPResponse

/// Transport-agnostic HTTP response. Bodies are raw bytes.
public struct HTTPResponse: Sendable,
							Encodable {
	// MARK: + Public scope

	public let requestID: UInt64
	public let statusCode: Int
	public let headers: HTTPHeaders
	public let data: Data

	public init(
		request: HTTPRequest,
		statusCode: Int,
		headers: HTTPHeaders,
		data: Data
	) {
		self.requestID = request.requestID
		self.statusCode = statusCode
		self.headers = headers
		self.data = data
	}
}
