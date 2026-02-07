//
//  HTTPMethodTests.swift
//  HTTPCoreTests
//
//  Created by vsmbd on 07/02/26.
//

import Foundation
import HTTPCore
import Testing

@Suite("HTTPMethod")
struct HTTPMethodTests {
	@Test("raw values match HTTP spec")
	func rawValues() {
		#expect(HTTPMethod.get.rawValue == "GET")
		#expect(HTTPMethod.post.rawValue == "POST")
		#expect(HTTPMethod.put.rawValue == "PUT")
		#expect(HTTPMethod.delete.rawValue == "DELETE")
		#expect(HTTPMethod.patch.rawValue == "PATCH")
		#expect(HTTPMethod.head.rawValue == "HEAD")
		#expect(HTTPMethod.options.rawValue == "OPTIONS")
	}

	@Test("CaseIterable includes all methods")
	func caseIterable() {
		let all = HTTPMethod.allCases
		#expect(all.contains(.get))
		#expect(all.contains(.post))
		#expect(all.count == 7)
	}

	@Test("Hashable allows use in sets")
	func hashable() {
		let set: Set<HTTPMethod> = [.get, .post, .get]
		#expect(set.count == 2)
		#expect(set.contains(.get))
		#expect(set.contains(.post))
	}
}
