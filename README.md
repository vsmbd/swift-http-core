# HTTPCore

A small Swift package that defines an opinionated, transport-agnostic HTTP contract (**HTTPCore**) plus first-party transport adapters.

The core design goal is deterministic request lifecycle tracking with explicit execution on `TaskQueue.background`, using:
- SwiftCore for queues, IDs, and timing primitives (as available in your workspace)
- EventDispatch for structured lifecycle events

This package is meant to be the HTTP boundary for the `vsmbd` workspace: app code talks to `HTTPCore` interfaces, not to any particular transport library.
This package is designed to compose with `swift-json` (product/module: `JSON`, enum: `JSON`) for JSON request/response handling.


## Package structure

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
      HTTPProcessingEvent.swift
      HTTPCorePolicy.swift
    HTTPCoreNativeCounters/
      include/NativeCounters.h
      NativeCounters.c
    URLSessionHTTPClient/
      URLSessionHTTPClient.swift
      URLSessionCancellable.swift
  Tests/
    HTTPCoreTests/
    URLSessionHTTPClientTests/
```

### Products

- **HTTPCore**: pure contract + event model (no transport). Depends on HTTPCoreNativeCounters, SwiftCore, EventDispatch.
- **URLSessionHTTPClient**: URLSession-based transport adapter (Apple + non-Darwin where FoundationNetworking is available).

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
let req = HTTPRequest(
  method: .post,
  url: URL(string: "https://api.example.com/users")!,
  headers: .init([ "Content-Type": "application/json" ]),
  body: body,
  timeout: 30
)
// requestID is assigned internally via nextRequestID()
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
- a stable request ID (from `nextRequestID()` at init)
- timestamps on each lifecycle event (`MonotonicNanostamp`)
- an explicit lifecycle (created → started → responseReceived → succeeded, or failed/cancelled)
- checkpoint correlation: caller passes a checkpoint into `execute`; implementations create successor checkpoints so the full chain is traceable
- normalized error taxonomy (`HTTPError` + `ErrorInfo` with checkpoint)

EventDispatch events (`HTTPProcessingEvent`) are sunk at key points; telemetry sinks can subscribe via EventDispatch.

## API surface

### Core types

```swift
public struct HTTPRequest: Sendable, Encodable {
  public let requestID: UInt64   // from nextRequestID() at init
  public let method: HTTPMethod
  public let url: URL
  public var headers: HTTPHeaders
  public var body: Data?
  public var timeout: TimeInterval?
  public init(method:url:headers:body:timeout:)
}

public struct HTTPResponse: Sendable, Encodable {
  public let requestID: UInt64
  public let statusCode: Int
  public let headers: HTTPHeaders
  public let data: Data
  public init(request: HTTPRequest, statusCode:headers:data:)
}

public typealias HTTPExecutionResult = CheckpointedResult<HTTPResponse, HTTPError>
// .success(HTTPResponse, Checkpoint) | .failure(ErrorInfo<HTTPError>)

public typealias HTTPExecutionCompletion = @Sendable (HTTPExecutionResult) -> Void

public protocol HTTPClient: Sendable {
  @discardableResult
  func execute(
    _ request: HTTPRequest,
    _ checkpoint: Checkpoint,
    completion: @escaping HTTPExecutionCompletion
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

```swift
public enum HTTPError: ErrorEntity {
  case cancelled
  case timeout
  case invalidResponse
  case transport(underlying: String)
}
```

## Lifecycle events (EventDispatch)

A single enum `HTTPProcessingEvent` covers all phases; each case carries request (and response/error when applicable) plus `timestamp: MonotonicNanostamp`. Clients sink events with a `Checkpoint` for correlation.

### Event cases and kind suffixes
- `created(request:timestamp:)` → kind `HTTPProcessingEvent_created`
- `started(request:timestamp:)` → `_started`
- `responseReceived(request:response:timestamp:)` → `_received`
- `succeeded(request:response:timestamp:)` → `_succeeded`
- `failed(request:error:timestamp:)` → `_failed`
- `cancelled(request:timestamp:)` → `_cancelled`

Events are sunk via `EventDispatcher.sink(_:checkpoint:extra:)`. The caller passes a checkpoint into `execute(_:_:completion:)`; the implementation uses it and creates successor checkpoints (e.g. `checkpoint.next(self)`) so the full execution chain is correlated.

### Redaction policy
`HTTPCorePolicy` is injected into clients: `allowQueryParametersInTelemetry`, `includeByteCountsInTelemetry`. Do not emit sensitive material by default; never emit raw bodies or Authorization headers unless explicitly enabled.

## Concurrency contract

### Execution
- HTTPClient.execute must schedule transport execution on TaskQueue.background.
- All EventDispatch emissions for a request must also occur on TaskQueue.background to preserve ordering and avoid accidental main-thread work.

### Completion delivery
URLSessionHTTPClient invokes completion on a configurable `completionQueue` (default: `TaskQueue.background`). Execution is scheduled on a configurable `queue` (default: `TaskQueue.background`). Both are `ConcurrentTaskQueue`; the contract does not expose DispatchQueue.

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
  policy: .init(),
  dispatcher: EventDispatch.default,
  queue: TaskQueue.background,
  completionQueue: TaskQueue.background
)

let req = HTTPRequest(
  method: .get,
  url: URL(string: "https://example.com")!,
  headers: .init(),
  body: nil,
  timeout: 30
)

client.execute(req, Checkpoint.checkpoint(self)) { result in
  switch result {
  case let .success(response, checkpoint): // use response, correlate via checkpoint
  case let .failure(errorInfo):            // ErrorInfo<HTTPError>
  }
  // runs on completionQueue (default: TaskQueue.background)
}
```

## Testing approach

- **HTTPCoreTests**: unit tests for HTTPRequest, HTTPResponse, HTTPMethod, HTTPHeaders, HTTPError, HTTPCorePolicy, HTTPProcessingEvent, HTTPExecutionResult (encoding, init, behaviour).
- **URLSessionHTTPClientTests**: URLProtocol stub (`StubURLProtocol`) and a recording `EventDispatcher`; suite runs with `.serialized` so the shared stub handler is safe. Tests cover:
  - success path (response + checkpoint, event order: created → started → responseReceived → succeeded)
  - error mapping (cancelled, timeout, invalidResponse, transport)
  - request translation (method, url, headers, timeout; body when URLProtocol exposes it)
  - checkpoint correlation (caller checkpoint for created event; delivery checkpoint from client)
  - cancel of in-flight request
- On Linux, add integration tests against a local server if needed.

## Versioning

Treat HTTPCore public APIs as stable contracts:
- breaking changes require a major version bump
- add new fields to event payloads in a backward-compatible way
