//
//  HTTPCorePolicyTests.swift
//  HTTPCoreTests
//
//  Created by vsmbd on 07/02/26.
//

import Foundation
import HTTPCore
import Testing

@Suite("HTTPCorePolicy")
struct HTTPCorePolicyTests {
	@Test("init default allows query and byte counts")
	func initDefault() {
		let policy = HTTPCorePolicy()
		#expect(policy.allowQueryParametersInTelemetry == true)
		#expect(policy.includeByteCountsInTelemetry == true)
	}

	@Test("init with explicit values")
	func initExplicit() {
		let policy = HTTPCorePolicy(
			allowQueryParametersInTelemetry: false,
			includeByteCountsInTelemetry: false
		)
		#expect(policy.allowQueryParametersInTelemetry == false)
		#expect(policy.includeByteCountsInTelemetry == false)
	}
}
