// swift-tools-version: 6.2

import PackageDescription

let package = Package(
	name: "HTTPCore",
	products: [
		.library(
			name: "HTTPCore",
			targets: ["HTTPCore"]
		),
		.library(
			name: "URLSessionHTTPClient",
			targets: ["URLSessionHTTPClient"]
		)
	],
	dependencies: [
		.package(
			url: "https://github.com/vsmbd/swift-core.git",
			branch: "main"
		),
		.package(
			url: "https://github.com/vsmbd/swift-eventdispatch.git",
			branch: "main"
		)
	],
	targets: [
		.target(
			name: "HTTPCore",
			dependencies: [
				"HTTPCoreNativeCounters",
				.product(
					name: "SwiftCore",
					package: "swift-core"
				),
				.product(
					name: "EventDispatch",
					package: "swift-eventdispatch"
				),
			],
			path: "Sources/HTTPCore"
		),
		.target(
			name: "HTTPCoreNativeCounters",
			path: "Sources/HTTPCoreNativeCounters",
			publicHeadersPath: "include"
		),
		.target(
			name: "URLSessionHTTPClient",
			dependencies: [
				"HTTPCore",
				.product(
					name: "SwiftCore",
					package: "swift-core"
				),
				.product(
					name: "EventDispatch",
					package: "swift-eventdispatch"
				),
			],
			path: "Sources/URLSessionHTTPClient"
		),
		.testTarget(
			name: "HTTPCoreTests",
			dependencies: [
				"HTTPCore",
				.product(
					name: "SwiftCore",
					package: "swift-core"
				)
			],
			path: "Tests/HTTPCoreTests"
		),
		.testTarget(
			name: "URLSessionHTTPClientTests",
			dependencies: [
				"URLSessionHTTPClient",
				.product(
					name: "SwiftCore",
					package: "swift-core"
				),
				.product(
					name: "EventDispatch",
					package: "swift-eventdispatch"
				)
			],
			path: "Tests/URLSessionHTTPClientTests"
		)
	]
)
