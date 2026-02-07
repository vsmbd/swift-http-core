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
- Provide policy-driven redaction to prevent sensitive data leakage.

4) Deterministic ordering
- Event emission and completion callbacks obey a documented ordering model.
- Prefer a single execution queue per request (background) to preserve ordering and reduce races.

## Implementation goals

5) URLSession transport adapter
- Provide a minimal URLSession-based implementation that supports:
  - GET and POST
  - headers
  - body Data
  - per-request timeout
  - cancellation
- Support non-Darwin where FoundationNetworking is available.

6) Composition with swift-json
- Standardize on `swift-json`'s `JSON` enum as the primary JSON type in this workspace.
- Keep HTTPCore contracts byte-oriented, but ensure adapters and helper layers treat `swift-json` as the default JSON boundary.

6) Composable policy surface
- Provide an injectable policy object for:
  - URL redaction
  - header filtering
  - optional metrics fields (byte counts, etc.)

## Quality goals

7) Testability
- Unit tests for mapping and error taxonomy.
- Tests for event emission ordering and payload stability.

8) Minimal public surface
- Keep v1 lean and predictable; add capabilities via adapters and policies rather than expanding the core contract prematurely.
