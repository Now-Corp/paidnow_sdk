# Everything under PaidnowSdk speaks the PaidNow wire protocol and nothing else:
# no web framework, no ORM, no host domain concepts. Credentials and logging are
# injected by the application that uses it, so the SDK can be configured per
# process and stubbed outright in tests.
#
# Keep it that way. Anything that needs to understand the host's own records
# belongs in the host application, mapped into plain hashes on the way in.
require 'paidnow_sdk/version'
require 'paidnow_sdk/errors'
require 'paidnow_sdk/config'
require 'paidnow_sdk/client'
require 'paidnow_sdk/delegate_token'
require 'paidnow_sdk/webhook_signature'
require 'paidnow_sdk/tradee_payload'
require 'paidnow_sdk/document_fetcher'

module PaidnowSdk
  class << self
    def config
      @config ||= Config.new
    end

    def configure
      yield(config)
      config
    end

    # Test seam.
    def reset_config!
      @config = nil
    end
  end
end
