RSpec.describe PaidnowSdk::Client do
  let(:api) { 'https://api.paidnow.test' }

  before { configure_sdk }

  it 'identifies itself with the SDK user agent by default' do
    request = stub_request(:post, "#{api}/tradee-data/create")
              .with(headers: { 'User-Agent' => "paidnow_sdk/#{PaidnowSdk::VERSION}" })
              .to_return(status: 200, body: '{}')

    described_class.new.create_tradee_data({}, 'dtoken')

    expect(request).to have_been_requested
  end

  it 'honours a user agent supplied by the host' do
    configure_sdk(user_agent: 'Acme/1.0')
    request = stub_request(:post, "#{api}/tradee-data/create")
              .with(headers: { 'User-Agent' => 'Acme/1.0' })
              .to_return(status: 200, body: '{}')

    described_class.new.create_tradee_data({}, 'dtoken')

    expect(request).to have_been_requested
  end
end
