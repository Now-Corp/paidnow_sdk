RSpec.describe PaidnowSdk::DelegateToken do
  let(:rsa) { OpenSSL::PKey::RSA.new(2048) }
  let(:tradee) { { id: 42, email: 'trade@example.test', name: 'Acme Plumbing', phone: '0400000000', abn: '123' } }

  before { configure_sdk(private_key: rsa.to_pem) }

  def decode(token)
    JWT.decode(token, rsa.public_key, true, algorithm: 'RS256')
  end

  it 'signs an RS256 token carrying the tradee as subject' do
    claims, header = decode(described_class.sign(tradee: tradee))

    expect(header['alg']).to eq('RS256')
    expect(header['kid']).to eq('key-1')
    expect(claims['sub']).to eq('42')
    expect(claims['iss']).to eq('issuer.test')
    expect(claims['aud']).to eq('paidnow.com')
    expect(claims['platform_id']).to eq('client-abc')
  end

  it 'embeds the tradee contact details' do
    claims, = decode(described_class.sign(tradee: tradee))

    expect(claims['tradee_data']).to eq(
      'email' => 'trade@example.test', 'name' => 'Acme Plumbing', 'phone' => '0400000000', 'abn' => '123'
    )
  end

  it 'expires ten minutes out' do
    claims, = decode(described_class.sign(tradee: tradee))

    expect(claims['exp'] - claims['iat']).to eq(600)
  end

  it 'refuses a tradee with no id' do
    expect { described_class.sign(tradee: tradee.merge(id: nil)) }
      .to raise_error(PaidnowSdk::InvalidPayload, /missing id/)
  end

  it 'defaults the audience to PaidNow and honours an override' do
    claims, = decode(described_class.sign(tradee: tradee))
    expect(claims['aud']).to eq(PaidnowSdk::Config::DEFAULT_TOKEN_AUDIENCE)

    configure_sdk(private_key: rsa.to_pem, token_audience: 'sandbox.paidnow.test')
    claims, = decode(described_class.sign(tradee: tradee))
    expect(claims['aud']).to eq('sandbox.paidnow.test')
  end

  it 'refuses to sign with no issuer configured' do
    configure_sdk(private_key: rsa.to_pem, token_issuer: nil)

    expect { described_class.sign(tradee: tradee) }
      .to raise_error(PaidnowSdk::ConfigurationError, /token_issuer/)
  end

  it 'refuses to sign with no key configured' do
    configure_sdk(private_key: nil)

    expect { described_class.sign(tradee: tradee) }.to raise_error(PaidnowSdk::ConfigurationError)
  end
end
