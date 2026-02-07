# NONGOALS

1) Not a full-featured networking stack
- No retries, backoff, circuit breakers, caching, cookie management, or background transfer support in v1.
- Those can be layered on later via policies or adapters.

2) Not an authentication framework
- No OAuth flows, token refresh, signing, or credential storage.

3) Not a JSON or serialization layer
- HTTPCore deals in bytes (Data) and HTTP semantics only.
- JSON modeling belongs in a separate package (swift-json). `swift-json` is the primary JSON representation for this workspace.

4) No implicit concurrency
- HTTPCore will not auto-select queues or use global dispatch without being explicit.
- No hidden main-thread callbacks.

5) No promise of perfect parity across all Swift targets
- URLSession behavior varies across Darwin vs swift-corelibs-foundation.
- HTTPCore will not guarantee identical behavior on every Swift-supported platform.

6) No leaking of transport types
- Public APIs must not expose URLSession, Alamofire, or other transport-specific types.
- Adapters are implementation details behind the HTTPClient protocol.

7) No sensitive data in telemetry by default
- Event payloads must not include raw bodies or authorization headers unless explicitly enabled via HTTPCorePolicy.
