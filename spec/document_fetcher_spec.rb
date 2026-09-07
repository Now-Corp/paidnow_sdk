RSpec.describe PaidnowSdk::DocumentFetcher do
  let(:url) { 'https://docs.paidnow.test/invoice.pdf' }

  before { configure_sdk }

  it 'returns the bytes for a real PDF' do
    stub_request(:get, url).to_return(status: 200, body: "%PDF-1.4\nbody")

    expect(described_class.new.fetch_pdf(url)).to start_with('%PDF-')
  end

  it 'raises InvalidContent when the body is not a PDF' do
    stub_request(:get, url).to_return(status: 200, body: '<html>expired</html>')

    expect { described_class.new.fetch_pdf(url) }
      .to raise_error(PaidnowSdk::DocumentFetcher::InvalidContent)
  end

  it 'raises DownloadFailed on a non-success status' do
    stub_request(:get, url).to_return(status: 403, body: '')

    expect { described_class.new.fetch_pdf(url) }
      .to raise_error(PaidnowSdk::DocumentFetcher::DownloadFailed, /status 403/)
  end

  it 'raises DownloadFailed when the connection fails' do
    stub_request(:get, url).to_timeout

    expect { described_class.new.fetch_pdf(url) }
      .to raise_error(PaidnowSdk::DocumentFetcher::DownloadFailed, /Failed to download document/)
  end
end
