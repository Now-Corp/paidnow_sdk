# Changelog

All notable changes to this gem are documented here. This project follows
[Semantic Versioning](https://semver.org).

## [0.2.0]

### Changed

- `WebhookSignature` verifies the timestamped signature PaidNow now sends: the
  HMAC covers `"{timestamp}.{payload}"` and the `X-PaidNow-Timestamp` header
  must be within `webhook_tolerance` of local time, so a captured delivery
  cannot be replayed once it goes stale. **Breaking:** `valid?` and `new` take
  a required `timestamp:` argument, and a signature over the body alone is no
  longer accepted.

### Added

- `Config#webhook_tolerance`, the webhook timestamp window in seconds.
  Defaults to 300; set it to `0` to skip the freshness check.

## [0.1.1]

### Removed

- `Client#submit_invoice` and `Client#invoice_status`, which were unreachable
  and spoke a different endpoint shape from the rest of the API.
- `Config#client_secret`, read only by the removed `#submit_invoice`.

### Changed

- The delegate token `iss` and `aud` claims and the request `User-Agent` are
  configuration (`token_issuer`, `token_audience`, `user_agent`) rather than
  hardcoded constants. `token_issuer` is required when signing tokens;
  `token_audience` defaults to `paidnow.com` and `user_agent` to
  `paidnow_sdk/<version>`.

## [0.1.0]

- Initial extraction: client, delegate token, tradee payload, webhook
  signature verification, and document fetching.
