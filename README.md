# Usage

Execute the client like so:

## Fetch raw payloads for multiple tickers

`$ bundle exec ruby main.rb -k <api-key> get BTC ETH`

## Fetch specific fields for multiple tickers

`$ bundle exec ruby main.rb -k <api-key> get-project symbol,name,price BTC ETH`

## Convert a ticker to a fiat currency

`$ bundle exec ruby main.rb -k <api-key> convert-fiat BTC EUR`

## Get the exchange rate between two tickers (by comparing to USD)

`$ bundle exec ruby main.rb -k <api-key> exchange BTC EUR`

# Tests

Execute unit tests with `$ bundle exec rspec`
