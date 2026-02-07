# swift-http-core

A small Swift package that defines an opinionated, transport-agnostic HTTP contract (**HTTPCore**) plus first-party transport adapters.

The core design goal is deterministic request lifecycle tracking with explicit execution on `TaskQueue.background`, using:
- SwiftCore for queues, IDs, and timing primitives (as available in your workspace)
- EventDispatch for structured lifecycle events

This package is meant to be the HTTP boundary for the `vsmbd` workspace: app code talks to `HTTPCore` interfaces, not to any particular transport library.
This package is designed to compose with `swift-json` (product/module: `JSON`, enum: `JSON`) for JSON request/response handling.


## Package structure

Recommended layout:

```
swift-http-core/
  Package.swift
  Sources/
    HTTPCore/
      HTTPClient.swift
      HTTPRequest.swift
      HTTPResponse.swift
      HTTPHeaders.swift
      HTTPMethod.swift
      HTTPError.swift
      HTTPEvents.swift
      HTTPCorePolicy.swift
    HTTPCoreURLSession/
      URLSessionHTTPClient.swift
      URLSessionCancellable.swift
  Tests/
    HTTPCoreTests/
    HTTPCoreURLSessionTests/
```

### Products

- HTTPCore: pure contract + event model (no transport)
- HTTPCoreURLSession: URLSession-based transport adapter (Apple + non-Darwin where FoundationNetworking is available)

If you later create an Alamofire adapter, keep it in a separate package or Apple-only target, depending on your workspace constraints.

## JSON integration (swift-json)

HTTPCore treats bodies as bytes (`Data`) at the contract boundary, but the **primary JSON representation for this workspace is `swift-json`**.

Guidance:
- Prefer building request bodies from `swift-json`'s `JSON` enum in call sites and higher-level helpers.
- Prefer decoding responses into `swift-json` `JSON` first, then decoding into `Codable` models as needed.
- HTTPCore itself should not become a JSON library; keep JSON conveniences in small helper extensions or adapters that depend on `swift-json`.

Example pattern:

```swift
import JSON   // swift-json module (enum JSON)
import HTTPCore

let payload: JSON = .object([
  "name": .string("Asha"),
  "age": .number(12)
])

let body = try payload.toData(prettyPrinted: false)
var req = HTTPRequest(
  id: uniqueID,  // obtain a unique id per request (e.g. SwiftCore Entity.nextID)
  method: .post,
  url: URL(string: "https://api.example.com/users")!,
  headers: .init([ "Content-Type": "application/json" ]),
  body: body,
  timeout: 30
)
```

## Design principles

### 1) Contracts are pure, transports are adapters
HTTPCore defines the public model and protocols. Transports implement `HTTPClient` and translate into concrete networking APIs.

### 2) Explicit concurrency only
All network execution is explicitly dispatched to `TaskQueue.background`.

- No work should occur on the caller thread by accident.
- Completion callbacks and event emissions must be deterministic and documented.

### 3) First-class observability
Every request has:
- a stable request ID
- start/end timestamps
- an explicit lifecycle (started → response received → completed or failed)
- normalized error taxonomy

EventDispatch events are emitted at key points to power telemetry sinks (Telme, ClickHouse, Grafana).

## Minimal v1 API surface (recommended)

### Core types

```swift
public struct HTTPRequest: Sendable {
  public let id: UInt64
  public let method: HTTPMethod
  public let url: URL
  public var headers: HTTPHeaders
  public var body: Data?
  public var timeout: TimeInterval?
}

public struct HTTPResponse: Sendable {
  public let requestID: UInt64
  public let statusCode: Int
  public let headers: HTTPHeaders
  public let data: Data
}

public protocol HTTPClient: Sendable {
  @discardableResult
  func execute(
    _ request: HTTPRequest,
    completion: @escaping @Sendable (Result<HTTPResponse, HTTPError>) -> Void
  ) -> Cancellable
}
```

### Cancellation

```swift
public protocol Cancellable: Sendable {
  func cancel()
}
```

### Errors

Keep errors actionable and stable:

```swift
public enum HTTPError: Error, Sendable, Equatable {
  case cancelled
  case timeout
  case invalidResponse
  case transport(UnderlyingError)
}
```

## Lifecycle events (EventDispatch)

Emit a small but sufficient set of events in v1. Keep payloads compact and stable.

### Event names
- http.request.created
- http.request.started
- http.response.received
- http.request.succeeded
- http.request.failed
- http.request.cancelled

### Suggested payload fields
- requestID
- method
- url (redaction policy applies)
- statusCode (when known)
- startTime, endTime, durationMs
- requestBytes, responseBytes (best-effort)
- error (normalized)

### Redaction policy
Do not emit sensitive material by default:
- strip or hash query parameters unless explicitly allowed
- never emit Authorization headers
- never emit raw bodies by default

Model this as a HTTPCorePolicy injected into clients.

## Concurrency contract

### Execution
- HTTPClient.execute must schedule transport execution on TaskQueue.background.
- All EventDispatch emissions for a request must also occur on TaskQueue.background to preserve ordering and avoid accidental main-thread work.

### Completion delivery
Pick one and document it:
- Option A: completion is invoked on TaskQueue.background
- Option B: completion is invoked on a caller-provided TaskQueue (default: background)

V1 recommendation: Option B, without exposing DispatchQueue in the public contract.

## URLSession adapter notes

### Imports for non-Darwin
If you want the adapter to build on Linux:

```swift
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
```

Feature parity is not guaranteed across all Swift targets, but basic GET/POST is expected where FoundationNetworking is supported.

## Quick start

```swift
let client: HTTPClient = URLSessionHTTPClient(
  session: .shared,
  policy: .default,
  dispatcher: eventDispatcher,
  queue: TaskQueue.background
)

let req = HTTPRequest(
  id: uniqueID,  // obtain a unique id per request (e.g. SwiftCore Entity.nextID)
  method: .get,
  url: URL(string: "https://example.com")!,
  headers: .init(),
  body: nil,
  timeout: 30
)

client.execute(req) { result in
  // runs on TaskQueue.background (or the configured callback queue)
}
```

## Testing approach

- Use URLProtocol stubbing on Apple platforms.
- On Linux, prefer integration tests against a local test server if needed.
- Validate:
  - request translation (method, headers, body)
  - response mapping (status, headers, data)
  - error mapping (cancelled, timeout, transport)
  - event ordering and timestamps

## Versioning

Treat HTTPCore public APIs as stable contracts:
- breaking changes require a major version bump
- add new fields to event payloads in a backward-compatible way
