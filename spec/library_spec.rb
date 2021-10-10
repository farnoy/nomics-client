require_relative '../lib/client'

RSpec.describe(Client) do
  RSpec.shared_context 'stub successful response', :shared_context => :metadata do
    before do
      stub_request(:get, "#{stub_base_url}/v1/currencies/ticker")
        .with(query: {**expected_request_query, key: stub_api_key})
        .to_return(status: 200, body: response.to_json)
    end
  end

  RSpec.shared_context 'stub successful response after retrying', :shared_context => :metadata do
    before do
      stub_request(:get, "#{stub_base_url}/v1/currencies/ticker")
        .with(query: {**expected_request_query, key: stub_api_key})
        .to_return(status: 429, body: 'API limit')
        .then
        .to_return(status: 200, body: response.to_json)
    end
  end

  RSpec.shared_context 'stub failed response', :shared_context => :metadata do
    before do
      stub_request(:get, "#{stub_base_url}/v1/currencies/ticker")
        .with(query: {**expected_request_query, key: stub_api_key})
        .to_return(status: 500, body: 'Internal Server Error')
    end
  end

  let(:stub_base_url) { 'https://test-nomics.com' }
  let(:stub_api_key) { 'letmein' }
  let(:test_client) { described_class.new(stub_base_url, stub_api_key) }
  let(:request_path) { '/v1/currencies/ticker' }

  context '#get' do
    subject { test_client.get(['ETH', 'BTC']) }

    let(:expected_request_query) { {ids: 'ETH,BTC'} }
    let(:response) do
      [{symbol: 'ETH', price: '256.00'}, {symbol: 'BTC', price: '123.06'}]
    end

    context 'with a successful response' do
      include_context 'stub successful response'

      it do
        should eq({BTC: {symbol: 'BTC', price: '123.06'}, ETH: {symbol: 'ETH', price: '256.00'}})
      end
    end

    context 'with a retried response' do
      include_context 'stub successful response after retrying'

      it do
        should eq({BTC: {symbol: 'BTC', price: '123.06'}, ETH: {symbol: 'ETH', price: '256.00'}})
      end
    end

    context 'with a failed response' do
      include_context 'stub failed response'

      it 'raises an exception' do
        expect { subject }.to raise_error(described_class::APIError, "API Error: 500 with body: Internal Server Error")
      end
    end

    context 'extensible parameters' do
      include_context 'stub successful response'

      let(:expected_request_query) { {ids: 'ETH', status: 'active'} }
      let(:response) do
        [{symbol: 'ETH', price: '384.00'}]
      end
      subject { test_client.get(['ETH'], status: 'active') }

      it { should eq({ETH: {symbol: 'ETH', price: '384.00'}}) }
    end
  end

  context '#get_project' do
    subject { test_client.get_project([:price, 'circulating_supply'], ['ETH', 'BTC']) }

    let(:expected_request_query) { {ids: 'ETH,BTC'} }
    let(:response) do
      [{symbol: 'ETH', price: '256.00', circulating_supply: '123', max_supply: '456'},
       {symbol: 'BTC', price: '123.06', circulating_supply: '456', max_supply: '789'}]
    end

    context 'with a successful response' do
      include_context 'stub successful response'

      it do
        should eq({BTC: {price: '123.06', circulating_supply: '456'},
                   ETH: {price: '256.00', circulating_supply: '123'}})
      end
    end

    context 'with a retried response' do
      include_context 'stub successful response after retrying'

      it do
        should eq({BTC: {price: '123.06', circulating_supply: '456'},
                   ETH: {price: '256.00', circulating_supply: '123'}})
      end
    end

    context 'with a failed response' do
      include_context 'stub failed response'

      it 'raises an exception' do
        expect { subject }.to raise_error(described_class::APIError, "API Error: 500 with body: Internal Server Error")
      end
    end

    context 'extensible parameters' do
      include_context 'stub successful response'

      let(:expected_request_query) { {ids: 'ETH', status: 'active'} }
      let(:response) do
        [{symbol: 'ETH', price: '384.00', circulating_supply: '123', max_supply: '456'}]
      end
      subject { test_client.get_project(%i[price circulating_supply], ['ETH'], status: 'active') }

      it { should eq({ETH: {price: '384.00', circulating_supply: '123'}}) }
    end
  end

  context '#convert_to_fiat' do
    subject { test_client.convert_to_fiat('ETH', 'EUR') }

    let(:expected_request_query) { {ids: 'ETH', convert: 'EUR'} }
    let(:response) do
      [{symbol: 'ETH', price: '45000.00'}]
    end

    context 'with a successful response' do
      include_context 'stub successful response'

      it do
        should eq(BigDecimal(45000))
      end
    end

    context 'with a retried response' do
      include_context 'stub successful response after retrying'

      it do
        should eq(BigDecimal(45000))
      end
    end

    context 'with a failed response' do
      include_context 'stub failed response'

      it 'raises an exception' do
        expect { subject }.to raise_error(described_class::APIError, "API Error: 500 with body: Internal Server Error")
      end
    end
  end

  context '#exchange_rate' do
    subject { test_client.exchange_rate('ETH', 'BTC') }

    let(:expected_request_query) { {ids: 'ETH,BTC'} }
    let(:response) do
      [{symbol: 'ETH', price: '45000.00'}, {symbol: 'BTC', price: '3000.23'}]
    end

    context 'with a successful response' do
      include_context 'stub successful response'

      it do
        should eq(BigDecimal(45000) / BigDecimal('3000.23'))
      end
    end

    context 'with a retried response' do
      include_context 'stub successful response after retrying'

      it do
        should eq(BigDecimal(45000) / BigDecimal('3000.23'))
      end
    end

    context 'with a failed response' do
      include_context 'stub failed response'

      it 'raises an exception' do
        expect { subject }.to raise_error(described_class::APIError, "API Error: 500 with body: Internal Server Error")
      end
    end
  end
end
