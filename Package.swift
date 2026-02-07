// swift-tools-version: 6.2

import PackageDescription

let package = Package(
	name: "HTTPCore",
	products: [
		.library(
			name: "HTTPCore",
			targets: ["HTTPCore"]
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
	]
)
