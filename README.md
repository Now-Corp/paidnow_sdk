# paidnow_sdk

A dependency-free Ruby client for the [PaidNow](https://paidnow.com) invoice
funding API. It signs delegate tokens, calls the API, verifies webhook
signatures, and fetches PaidNow-hosted documents.

No web framework, no ORM, no domain model of its own: hashes in, parsed JSON
out. Your application owns its records and maps them into plain hashes on the
way in.

## Installation

The gem is not published to a gem server. It is installed straight from this
public repository, so no registry account or token is involved. In your
`Gemfile`:

```ruby
gem 'paidnow_sdk', git: 'https://github.com/Now-Corp/paidnow_sdk', tag: 'v0.1.0'
```

Pin the `tag`. Without it Bundler tracks the default branch and you will pick
up unreleased changes; `Gemfile.lock` records the exact commit either way.
Released versions are listed at
[tags](https://github.com/Now-Corp/paidnow_sdk/tags).

To upgrade, change the tag and run `bundle update paidnow_sdk`.

Or, from a checkout:

```ruby
gem 'paidnow_sdk', path: '../paidnow_sdk'
```

## Configuration

Configure it once at boot. The SDK never reads `ENV` or a settings file itself,
so the values can differ per process and be replaced wholesale in tests.

```ruby
PaidnowSdk.configure do |config|
  config.client_id      = ENV['PAIDNOW_CLIENT_ID']
  config.api_url        = ENV['PAIDNOW_API_URL']
  config.web_url        = ENV['PAIDNOW_WEB_URL']
  config.private_key    = ENV['PAIDNOW_PRIVATE_KEY']
  config.private_key_id = ENV['PAIDNOW_PRIVATE_KEY_ID']
  config.webhook_secret = ENV['PAIDNOW_WEBHOOK_SECRET']
  config.token_issuer   = 'your-platform.example'
  config.logger         = Logger.new($stdout)
end
```

| Setting | Required | Default | Meaning |
| --- | --- | --- | --- |
| `client_id` | yes | — | Your integrator id, sent as `X-Client-Id`. |
| `api_url` | yes | — | Base URL of the PaidNow API. |
| `private_key` | to sign tokens | — | RSA private key, PEM. Literal `\n` sequences are unescaped for you. |
| `private_key_id` | to sign tokens | — | Key id, sent as the JWT `kid` header. |
| `token_issuer` | to sign tokens | — | Platform identity for the `iss` claim, issued to you by PaidNow. |
| `token_audience` | no | `paidnow.com` | The `aud` claim PaidNow expects. |
| `webhook_secret` | to verify webhooks | — | Shared secret for the delivery HMAC. |
| `web_url` | no | — | Base URL of the PaidNow web app, if you link to it. |
| `user_agent` | no | `paidnow_sdk/<version>` | Sent on every request. |
| `timeout` | no | `15` | Seconds, applied to every HTTP call. |
| `stub_api` | no | `false` | When true, `Client#create_tradee_data` returns a fake session id and makes no network call. |
| `logger` | no | null logger | Used only for best-effort notification failures. |

## What it offers

| Object | Responsibility |
| --- | --- |
| `PaidnowSdk::Client` | HTTP transport. Hashes in, parsed JSON out, `RequestError` otherwise. |
| `PaidnowSdk::DelegateToken` | Signs the short-lived RS256 token for one tradee. Takes a plain hash. |
| `PaidnowSdk::TradeePayload` | Validates the six sections the tradee-data endpoint expects. |
| `PaidnowSdk::WebhookSignature` | Verifies the HMAC signature on an incoming webhook. |
| `PaidnowSdk::DocumentFetcher` | Downloads a document and proves it is a PDF. |

## Usage

Opening a tradee session:

```ruby
token = PaidnowSdk::DelegateToken.sign(
  tradee: { id: 42, email: 'tradee@example.com', name: 'Acme Plumbing',
            phone: '+61400000000', abn: '12345678901' }
)

payload = PaidnowSdk::TradeePayload.new(
  tradee: {}, business: {}, invoice: {},
  bank_details: {}, address: {}, strata_manager: {}
)

response = PaidnowSdk::Client.new.create_tradee_data(payload.to_h, token)
```

Notifying PaidNow about an invoice. Both notifications are best effort: they
return `nil` rather than raising if PaidNow is unreachable, because the caller
has already acted locally and an outage must not undo that.

```ruby
client = PaidnowSdk::Client.new
client.notify_invoice_rejection('INV-001', 'Duplicate invoice')
client.notify_invoice_processed('INV-001', 'approved', token)
```

Verifying a webhook and fetching the document it points at:

```ruby
raise 'bad signature' unless PaidnowSdk::WebhookSignature.valid?(
  payload: request.raw_post,
  signature: request.headers['X-Paidnow-Signature']
)

bytes = PaidnowSdk::DocumentFetcher.new.fetch_pdf(document_url)
```

`fetch_pdf` raises `DownloadFailed` (worth retrying) or `InvalidContent` (not
worth retrying) and returns the raw bytes otherwise.

## Errors

All errors descend from `PaidnowSdk::Error`.

- `RequestError` — non-2xx response, or the request never completed. Carries
  `#status` when there was one.
- `ConfigurationError` — a setting the operation needs was never supplied.
- `InvalidPayload` — the hash you passed is missing something required.
- `DocumentFetcher::DownloadFailed` / `DocumentFetcher::InvalidContent`.

## Development

No database, no framework, no fixtures:

```shell
bundle install
bundle exec rake
```

## License

Proprietary. The source is published openly so it can be read and audited, but
that is not an open-source licence and it grants no right to run or
redistribute the gem. See [LICENSE](LICENSE), and contact Now Corp if you want
to integrate.
