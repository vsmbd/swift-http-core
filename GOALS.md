# GOALS

## Architecture goals

1) Transport-agnostic HTTP contract
- Define a small, stable set of types and protocols (HTTPRequest, HTTPResponse, HTTPClient, HTTPError).
- Ensure app and higher-level modules depend only on HTTPCore contracts.

2) Explicit concurrency using SwiftCore
- All network work is dispatched explicitly using TaskQueue.background.
- No implicit thread-hopping, no accidental main-thread execution.

3) Structured lifecycle tracking using EventDispatch
- Emit deterministic lifecycle events for every request with stable identifiers and timestamps.
- Caller passes a checkpoint into `execute(_:_:completion:)`; implementations use it and create successor checkpoints so the full execution chain is correlated.
- Provide policy-driven redaction (`HTTPCorePolicy`) to prevent sensitive data leakage.

4) Deterministic ordering
- Event emission and completion callbacks obey a documented ordering model.
- Prefer a single execution queue per request (background) to preserve ordering and reduce races.

## Implementation goals

5) URLSession transport adapter (URLSessionHTTPClient)
- Provide a minimal URLSession-based implementation that supports:
  - all HTTP methods (GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS via HTTPMethod)
  - headers, body Data, per-request timeout
  - cancellation (Cancellable)
  - configurable queue and completionQueue (default: TaskQueue.background)
- Support non-Darwin where FoundationNetworking is available.

6) Composition with swift-json
- Standardize on `swift-json`'s `JSON` enum as the primary JSON type in this workspace.
- Keep HTTPCore contracts byte-oriented, but ensure adapters and helper layers treat `swift-json` as the default JSON boundary.

7) Composable policy surface
- Provide an injectable policy object (`HTTPCorePolicy`) for:
  - URL redaction (`allowQueryParametersInTelemetry`)
  - optional metrics fields (`includeByteCountsInTelemetry`)

## Quality goals

8) Testability
- Unit tests (HTTPCoreTests) for types, encoding, error taxonomy, execution result.
- Integration-style tests (URLSessionHTTPClientTests) with URLProtocol stub and recording EventDispatcher; event ordering, checkpoint correlation, error mapping, request translation, cancellation.

9) Minimal public surface
- Keep the core contract lean; add capabilities via adapters and policies rather than expanding the core prematurely.
