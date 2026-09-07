require 'jwt'
require 'securerandom'

module PaidnowSdk
  # Signs the short-lived RS256 token that authorises one tradee's PaidNow
  # session. Takes a plain hash so nothing about the host's models leaks in here.
  class DelegateToken
    LIFETIME_SECONDS = 600

    REQUIRED_KEYS = %i[id].freeze

    attr_reader :tradee, :config

    # tradee: { id:, email:, name:, phone:, abn: }
    def self.sign(tradee:, config: PaidnowSdk.config)
      new(tradee: tradee, config: config).sign
    end

    def initialize(tradee:, config: PaidnowSdk.config)
      @tradee = tradee || {}
      @config = config
    end

    def sign
      validate!

      JWT.encode(payload, config.rsa_key, 'RS256', header_fields)
    end

    private

    def validate!
      missing = REQUIRED_KEYS.reject { |key| tradee[key] }
      raise InvalidPayload, "tradee is missing #{missing.join(', ')}" if missing.any?
    end

    def payload
      now = Time.now.to_i

      {
        iss: config.issuer!,
        aud: config.token_audience,
        sub: tradee[:id].to_s,
        exp: now + LIFETIME_SECONDS,
        iat: now,
        jti: "#{now}/#{SecureRandom.hex(18)}",
        platform_id: config.client_id,
        tradee_data: tradee_data
      }
    end

    def tradee_data
      {
        email: tradee[:email],
        name: tradee[:name],
        phone: tradee[:phone],
        abn: tradee[:abn]
      }
    end

    def header_fields
      { kid: config.private_key_id, typ: 'JWT' }
    end
  end
end
