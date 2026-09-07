RSpec.describe PaidnowSdk::Client do
  let(:api) { 'https://api.paidnow.test' }

  before { configure_sdk }

  describe '#notify_invoice_rejection' do
    it 'truncates the reason to 500 characters' do
      request = stub_request(:post, "#{api}/invoice/rejection")
                .with(body: { invoice_number: 'SM1001', rejection_reason: "#{'x' * 497}..." })
                .to_return(status: 200, body: '{"ok":true}')

      described_class.new.notify_invoice_rejection('SM1001', 'x' * 600)

      expect(request).to have_been_requested
    end

    it 'returns nil and logs rather than raising when PaidNow rejects the call' do
      stub_request(:post, "#{api}/invoice/rejection").to_return(status: 500, body: 'boom')
      logger = instance_double(Logger)
      configure_sdk(logger: logger)
      expect(logger).to receive(:error).with(/Failed to notify invoice rejection SM1001/)

      expect(described_class.new.notify_invoice_rejection('SM1001', 'nope')).to be_nil
    end
  end

  describe '#notify_invoice_processed' do
    it 'sends the action with the delegate token' do
      request = stub_request(:post, "#{api}/invoice/processed")
                .with(body: { invoice_number: 'SM1001', action: 'process' },
                      headers: { 'Authorization' => 'Bearer dtoken' })
                .to_return(status: 200, body: '{"ok":true}')

      described_class.new.notify_invoice_processed('SM1001', 'process', 'dtoken')

      expect(request).to have_been_requested
    end
  end
end
