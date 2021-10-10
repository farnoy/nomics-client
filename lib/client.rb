require 'json'
require 'memoist'
require 'faraday'
require 'faraday_middleware'
require 'bigdecimal'

class Client < Struct.new(:base_url, :api_key)
  extend Memoist

  class APIError < Exception
  end

  def get(tickers, **query)
    response = client.get("/v1/currencies/ticker", {ids: tickers.join(","), **query})
    if response.status == 200
      JSON
        .parse(response.body, symbolize_names: true)
        .map { |data| [data.fetch(:symbol).to_sym, data] }
        .to_h
    else
      raise APIError, "API Error: #{response.status} with body: #{response.body}"
    end
  end

  def get_project(projection, tickers, **query)
    symbolized_projection = Array(projection).map { |x| x.to_sym }
    get(tickers, **query)
      .transform_values { |data| data.slice(*symbolized_projection) }
  end

  def convert_to_fiat(ticker, fiat)
    BigDecimal(get_project(:price, [ticker], convert: fiat).fetch(ticker.to_sym).fetch(:price))
  end

  def exchange_rate(from, to)
    response = get_project(:price, [from, to])
    from_price = BigDecimal(response.fetch(from.to_sym).fetch(:price))
    to_price = BigDecimal(response.fetch(to.to_sym).fetch(:price))
    from_price / to_price
  end

  private
  def client
    Faraday.new(url: self.base_url, params: {key: self.api_key}) do |conn|
      conn.request :retry, {max: 3, interval: 1, backoff_factor: 2, retry_statuses: [429]}
      # Can't use the middleware below because 429 responses are not JSON :(
      # conn.response :json, {parser_options: {symbolize_names: true}}
    end
  end
  memoize :client
end
