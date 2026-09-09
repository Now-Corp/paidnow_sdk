# Changelog

All notable changes to this gem are documented here. This project follows
[Semantic Versioning](https://semver.org).

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
