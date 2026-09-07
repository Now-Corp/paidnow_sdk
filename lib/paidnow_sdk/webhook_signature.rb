require 'openssl'
require 'digest'

module PaidnowSdk
  # Verifies the HMAC signature PaidNow sends with each webhook delivery.
  class WebhookSignature
    PREFIX = 'sha256='.freeze

    def self.valid?(payload:, signature:, config: PaidnowSdk.config)
      new(payload: payload, signature: signature, config: config).valid?
    end

    attr_reader :payload, :signature, :config

    def initialize(payload:, signature:, config: PaidnowSdk.config)
      @payload   = payload
      @signature = signature
      @config    = config
    end

    def valid?
      return false if signature.to_s.empty? || secret.to_s.empty?

      secure_compare?(expected, signature)
    end

    private

    def secret
      config.webhook_secret
    end

    def expected
      PREFIX + OpenSSL::HMAC.hexdigest('SHA256', secret, payload.to_s)
    end

    # ActiveSupport::SecurityUtils.secure_compare, minus ActiveSupport: digest
    # first so the comparison is length-independent, then compare byte by byte.
    # Named with `?` per Ruby convention; ActiveSupport spells these without.
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
