require 'logger'
require 'openssl'
require 'paidnow_sdk/version'

module PaidnowSdk
  # Credentials and knobs, supplied by the host application. Nothing here reads
  # ENV or a settings file on its own -- that is the host's job, so the SDK can
  # be configured differently per process and stubbed outright in tests.
  class Config
    attr_accessor :client_id, :api_url, :web_url,
                  :private_key, :private_key_id, :webhook_secret,
                  :webhook_tolerance, :logger, :stub_api, :timeout,
                  :token_issuer, :token_audience, :user_agent

    DEFAULT_TIMEOUT_SECONDS = 15
    DEFAULT_WEBHOOK_TOLERANCE_SECONDS = 300

    # PaidNow's own identity: what it expects in the `aud` claim of a delegate
    # token. The same for every integrator, so it is a default rather than a
    # required setting.
    DEFAULT_TOKEN_AUDIENCE = 'paidnow.com'.freeze

    DEFAULT_USER_AGENT = "paidnow_sdk/#{PaidnowSdk::VERSION}".freeze

    def initialize
      @logger            = Logger.new(IO::NULL)
      @stub_api          = false
      @timeout           = DEFAULT_TIMEOUT_SECONDS
      @webhook_tolerance = DEFAULT_WEBHOOK_TOLERANCE_SECONDS
      @token_audience    = DEFAULT_TOKEN_AUDIENCE
      @user_agent        = DEFAULT_USER_AGENT
    end

    def api_base
      api_url.to_s.chomp('/')
    end

    def web_base
      web_url.to_s.chomp('/')
    end

    def stub_api?
      stub_api == true
    end

    # Identifies the integrating platform in the `iss` claim. There is no
    # sensible default -- PaidNow issues one per integrator -- so it is
    # required rather than guessed.
    def issuer!
      raise ConfigurationError, 'token_issuer is not configured' if token_issuer.to_s.empty?

      token_issuer
    end

    # PaidNow's private keys are distributed with literal \n sequences.
    def rsa_key
      raise ConfigurationError, 'private_key is not configured' if private_key.to_s.empty?

      @rsa_key ||= OpenSSL::PKey.read(private_key.to_s.gsub('\n', "\n"))
    end
  end
end
