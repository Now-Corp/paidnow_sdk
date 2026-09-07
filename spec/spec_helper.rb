# This gem has no Rails in it and no Rails in its tests. If a spec here ever
# needs Rails to pass, the SDK has grown a dependency it is not allowed to have.
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'webmock/rspec'
require 'paidnow_sdk'

RSpec.configure do |config|
  config.before { PaidnowSdk.reset_config! }
end

def configure_sdk(**overrides)
  PaidnowSdk.configure do |c|
    c.client_id      = 'client-abc'
    c.api_url        = 'https://api.paidnow.test/'
    c.web_url        = 'https://app.paidnow.test/'
    c.private_key_id = 'key-1'
    c.token_issuer   = 'issuer.test'
    c.webhook_secret = 'whsec'
    overrides.each { |key, value| c.public_send("#{key}=", value) }
  end
end
