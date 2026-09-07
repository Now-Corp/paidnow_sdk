RSpec.describe PaidnowSdk::WebhookSignature do
  let(:payload) { '{"event":"invoice.paid"}' }

  before { configure_sdk }

  def signature_for(body, secret = 'whsec')
    "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', secret, body)}"
  end

  it 'accepts a signature produced with the configured secret' do
    expect(described_class.valid?(payload: payload, signature: signature_for(payload))).to be true
  end

  it 'rejects a signature produced with a different secret' do
    expect(described_class.valid?(payload: payload,
                                  signature: signature_for(
                                    payload, 'wrong'
                                  ))).to be false
  end

  it 'rejects a signature for a different body' do
    expect(described_class.valid?(payload: payload, signature: signature_for('{}'))).to be false
  end

  it 'rejects a missing signature' do
    expect(described_class.valid?(payload: payload, signature: nil)).to be false
  end

  it 'rejects everything when no secret is configured' do
    configure_sdk(webhook_secret: nil)

    expect(described_class.valid?(payload: payload, signature: signature_for(payload))).to be false
  end
end
