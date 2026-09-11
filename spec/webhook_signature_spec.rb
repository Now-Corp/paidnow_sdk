RSpec.describe PaidnowSdk::WebhookSignature do
  let(:payload)   { '{"event":"invoice.paid"}' }
  let(:timestamp) { Time.now.to_i.to_s }

  before { configure_sdk }

  def signature_for(body, time = timestamp, secret = 'whsec')
    "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', secret, "#{time}.#{body}")}"
  end

  def valid?(**overrides)
    args = { payload: payload, timestamp: timestamp, signature: signature_for(payload) }
    args.update(overrides)

    described_class.valid?(**args)
  end

  it 'accepts a signature produced with the configured secret' do
    expect(valid?).to be true
  end

  it 'rejects a signature produced with a different secret' do
    expect(valid?(signature: signature_for(payload, timestamp, 'wrong'))).to be false
  end

  it 'rejects a signature for a different body' do
    expect(valid?(signature: signature_for('{}'))).to be false
  end

  it 'rejects a missing signature' do
    expect(valid?(signature: nil)).to be false
  end

  it 'rejects everything when no secret is configured' do
    configure_sdk(webhook_secret: nil)

    expect(valid?).to be false
  end

  describe 'replay protection' do
    it 'rejects a signature that covers the body alone' do
      legacy = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', 'whsec', payload)}"

      expect(valid?(signature: legacy)).to be false
    end

    it 'rejects a timestamp older than the tolerance, signature and all' do
      old = (Time.now.to_i - 301).to_s

      expect(valid?(timestamp: old, signature: signature_for(payload, old))).to be false
    end

    it 'accepts a timestamp inside the tolerance' do
      recent = (Time.now.to_i - 299).to_s

      expect(valid?(timestamp: recent, signature: signature_for(payload, recent))).to be true
    end

    it 'rejects a timestamp too far in the future' do
      ahead = (Time.now.to_i + 301).to_s

      expect(valid?(timestamp: ahead, signature: signature_for(payload, ahead))).to be false
    end

    it 'honours a configured tolerance' do
      configure_sdk(webhook_tolerance: 3600)
      old = (Time.now.to_i - 1800).to_s

      expect(valid?(timestamp: old, signature: signature_for(payload, old))).to be true
    end

    it 'skips the freshness check when the tolerance is zero' do
      configure_sdk(webhook_tolerance: 0)
      old = (Time.now.to_i - 86_400).to_s

      expect(valid?(timestamp: old, signature: signature_for(payload, old))).to be true
    end

    it 'rejects a missing timestamp' do
      expect(valid?(timestamp: nil, signature: signature_for(payload, nil))).to be false
    end

    it 'rejects a timestamp that is not unix seconds' do
      stamp = '2026-09-11T00:00:00Z'

      expect(valid?(timestamp: stamp, signature: signature_for(payload, stamp))).to be false
    end
  end
end
