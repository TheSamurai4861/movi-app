## Core Network (Dio)

This directory provides the app-wide networking infrastructure (Dio + interceptors + executor).

### Building the client

- `HttpClientFactory` creates a configured `Dio` instance.
- `AuthInterceptor` is enabled only when an `AuthTokenProvider` is provided.
- `LocaleInterceptor` adds `Accept-Language` when a `LocaleCodeProvider` is provided.
- `RetryInterceptor` retries transient failures at the Dio layer (timeouts/connection + 429/5xx).

### Executing calls

Use `NetworkExecutor.run<T, R>()` for all network calls from data sources.

Key contracts:

- **HTTP status handling**: `validateStatus` is 2xx only, so Dio raises `DioExceptionType.badResponse` on 4xx/5xx. Map to failures via `mapDioToFailure`.
- **Retries/backoff**: optional retry loop inside `NetworkExecutor` (separate from `RetryInterceptor`).
- **Concurrency limiting**: optional `concurrencyKey` groups calls under the same limiter (e.g. `"tmdb"`).
- **In-flight deduplication**: provide `dedupKey` to share the same in-flight request among concurrent callers.
  - The executor internally scopes the key by response type `T` to avoid unsafe casts when the same key is reused for different `T`.
- **In-memory cache (LRU + TTL)**: when `dedupKey` is provided, responses can be cached for a short time (`cacheTtl` or `memoryCacheDefaultTtl`).
  - Cached responses are reconstructed only for the `mapper` stage; request metadata is preserved for headers/query parameters, but it’s not a full replay of the original request lifecycle.
- **Anti-hang timeouts**: `inflightJoinTimeout` (waiting an existing in-flight) and `limiterAcquireTimeout` (waiting a concurrency slot) can be tuned in `NetworkExecutor`.

### Recommended conventions

- Use a stable `concurrencyKey` per upstream (e.g. `"tmdb"`, `"iptv"`).
- Make `dedupKey` unique per endpoint + parameters (method/path/query + locale + profile).
- Prefer a single pattern in data sources:
  - `DataSource -> executor.run(...) -> parse DTO -> map to Entity`
