require 'http'
require 'securerandom'

module PaidnowSdk
  # HTTP transport for the PaidNow API. Hashes in, parsed JSON out, RequestError
  # on anything else.
  class Client
    JSON_HEADERS = {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }.freeze

    REJECTION_REASON_LIMIT = 500

    attr_reader :config, :access_token

    def initialize(access_token: nil, config: PaidnowSdk.config)
      @access_token = access_token
      @config       = config
    end

    def create_tradee_data(payload, delegate_token)
      return stub_tradee_data_response if config.stub_api?

      post_json('/tradee-data/create', payload, delegated_headers(delegate_token))
    end

    # Returns nil instead of raising: the caller has already rejected the invoice
    # locally, and PaidNow being unreachable must not undo that.
    def notify_invoice_rejection(invoice_number, rejection_reason)
      post_json(
        '/invoice/rejection',
        invoice_number: invoice_number.to_s,
        rejection_reason: truncate(rejection_reason.to_s, REJECTION_REASON_LIMIT)
      )
    rescue HTTP::Error, RequestError => e
      log_failure("notify invoice rejection #{invoice_number}", e)
      nil
    end

    # Same tolerance as notify_invoice_rejection: best-effort notification.
    def notify_invoice_processed(invoice_number, action, delegate_token)
      post_json(
        '/invoice/processed',
        { invoice_number: invoice_number.to_s, action: action.to_s },
        delegated_headers(delegate_token)
      )
    rescue HTTP::Error, RequestError => e
      log_failure("notify invoice processed #{invoice_number}", e)
      nil
    end

    private

    def post_json(path, body, extra_headers = {})
      request(:post, path, extra_headers, body)
    end

    def request(method, path, extra_headers = {}, body = nil)
      response = HTTP
                 .timeout(config.timeout)
                 .headers(default_headers.merge(extra_headers))
                 .send(method, "#{config.api_base}#{path}", json: body)

      handle_response(response)
    rescue HTTP::Error => e
      raise RequestError, "HTTP Error: #{e.message}"
    end

    def default_headers
      headers = JSON_HEADERS.merge('User-Agent' => config.user_agent)
      headers['Authorization'] = "Bearer #{access_token}" if access_token
      headers
    end

    def delegated_headers(delegate_token)
      {
        'Authorization' => "Bearer #{delegate_token}",
        'X-Client-Id' => config.client_id
      }
    end

    def handle_response(response)
      status = response.status

      return response.parse(:json) if status.to_i.between?(200, 299)

      raise RequestError.new("#{status_label(status)}: #{response.body}", status.to_i)
    end

    def status_label(status)
      case status.to_i
      when 401 then 'Unauthorized'
      when 404 then 'Not Found'
      when 422 then 'Unprocessable Entity'
      else "Error (#{status})"
      end
    end

    def stub_tradee_data_response
      { 'data' => { 'redis_session_id' => "stub-session-#{SecureRandom.hex(8)}" } }
    end

    def log_failure(what, error)
      config.logger.error("[PaidNow] Failed to #{what}: #{error.message}")
    end

    # ActiveSupport's String#truncate, minus ActiveSupport.
    def truncate(text, length)
      return text if text.length <= length

      "#{text[0, length - 3]}..."
    end
  end
end
