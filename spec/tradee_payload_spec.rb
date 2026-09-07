RSpec.describe PaidnowSdk::TradeePayload do
  let(:sections) do
    {
      tradee: { tradee_id: 'TRD-1' },
      business: { abn: '123' },
      invoice: { invoice_number: 'SM1001' },
      bank_details: { bsb: '000-000' },
      address: { postcode: '2000' },
      strata_manager: { strata_manager_id: 'SM-9' }
    }
  end

  it 'keeps the six sections PaidNow expects' do
    expect(described_class.new(sections).to_h.keys).to eq(described_class::SECTIONS)
  end

  it 'accepts string keys' do
    stringified = sections.transform_keys(&:to_s)

    expect(described_class.new(stringified).to_h[:tradee]).to eq(tradee_id: 'TRD-1')
  end

  it 'refuses a payload missing a section' do
    expect { described_class.new(sections.reject { |k, _| k == :address }) }
      .to raise_error(PaidnowSdk::InvalidPayload, /address/)
  end

  it 'refuses a section that is not a hash' do
    expect { described_class.new(sections.merge(invoice: nil)) }
      .to raise_error(PaidnowSdk::InvalidPayload, /invoice/)
  end

  it 'refuses something that is not a hash at all' do
    expect { described_class.new('nope') }.to raise_error(PaidnowSdk::InvalidPayload)
  end
end
