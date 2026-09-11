require 'openssl'
require 'digest'

module PaidnowSdk
  # Verifies the HMAC signature PaidNow sends with each webhook delivery.
  #
  # PaidNow signs "{timestamp}.{payload}" rather than the payload alone, and
  # sends the timestamp in `X-PaidNow-Timestamp`. Both halves matter: the
  # signature proves the body and the timestamp were sent together, and
  # rejecting a timestamp outside the tolerance window is what stops a captured
  # request from being replayed later.
  class WebhookSignature
    PREFIX = 'sha256='.freeze

    def self.valid?(payload:, signature:, timestamp:, config: PaidnowSdk.config)
      new(payload: payload, signature: signature, timestamp: timestamp, config: config).valid?
    end

    attr_reader :payload, :signature, :timestamp, :config

    def initialize(payload:, signature:, timestamp:, config: PaidnowSdk.config)
      @payload   = payload
      @signature = signature
      @timestamp = timestamp
      @config    = config
    end

    def valid?
      return false if signature.to_s.empty? || secret.to_s.empty?
      return false unless fresh?

      secure_compare?(expected, signature)
    end

    private

    def secret
      config.webhook_secret
    end

    def sent_at
      @sent_at ||= Integer(timestamp.to_s, 10) if timestamp.to_s.match?(/\A\d+\z/)
    end

    def fresh?
      return false if sent_at.nil?
      return true if tolerance.zero?

      (Time.now.to_i - sent_at).abs <= tolerance
    end

    def tolerance
      value = config.webhook_tolerance
      value.nil? ? Config::DEFAULT_WEBHOOK_TOLERANCE_SECONDS : value.to_i
    end

    def signed_payload
      "#{timestamp}.#{payload}"
    end

    def expected
      PREFIX + OpenSSL::HMAC.hexdigest('SHA256', secret, signed_payload)
    end

    # ActiveSupport::SecurityUtils.secure_compare, minus ActiveSupport: digest
    # first so the comparison is length-independent, then compare byte by byte.
    def secure_compare?(left, right)
      fixed_length_secure_compare?(Digest::SHA256.digest(left),
                                   Digest::SHA256.digest(right)) && left == right
    end

    def fixed_length_secure_compare?(left, right)
      return false unless left.bytesize == right.bytesize

      bytes = left.unpack("C#{left.bytesize}")
      result = 0
      right.each_byte { |byte| result |= byte ^ bytes.shift }
      result.zero?
    end
  end
end
