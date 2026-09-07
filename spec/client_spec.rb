RSpec.describe PaidnowSdk::Client do
  let(:api) { 'https://api.paidnow.test' }

  before { configure_sdk }

  describe '#create_tradee_data' do
    it 'posts the payload with the delegate token and client id' do
      request = stub_request(:post, "#{api}/tradee-data/create")
                .with(
                  body: { tradee: { tradee_id: 'TRD-1' } },
                  headers: { 'Authorization' => 'Bearer dtoken', 'X-Client-Id' => 'client-abc' }
                )
                .to_return(status: 200, body: '{"data":{"redis_session_id":"sess-1"}}')

      result = described_class.new.create_tradee_data({ tradee: { tradee_id: 'TRD-1' } }, 'dtoken')

      expect(result.dig('data', 'redis_session_id')).to eq('sess-1')
      expect(request).to have_been_requested
    end

    it 'raises RequestError carrying the status on a 422' do
      stub_request(:post, "#{api}/tradee-data/create").to_return(status: 422, body: 'bad tradee')

      expect { described_class.new.create_tradee_data({}, 'dtoken') }
        .to raise_error(PaidnowSdk::RequestError, /Unprocessable Entity: bad tradee/) { |e|
              expect(e.status).to eq(422)
            }
    end

    it 'never touches the network when the API is stubbed out' do
      configure_sdk(stub_api: true)

      result = described_class.new.create_tradee_data({}, 'dtoken')

      expect(result.dig('data', 'redis_session_id')).to start_with('stub-session-')
      expect(WebMock).not_to have_requested(:post, "#{api}/tradee-data/create")
    end
  end
end
