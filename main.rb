require 'slop'
require_relative 'lib/client'

opts = Slop.parse do |o|
  o.bool '-h', '--help', default: false
  o.string '-k', '--api-key', required: true
  o.string '-u', '--url', default: 'https://api.nomics.com/v1/'
  o.separator "COMMANDS"
  o.separator "get [TICKER...]"
  o.separator "get-project PROJECTION [TICKER...]"
  o.separator "convert-fiat TICKER FIAT"
  o.separator "exchange FROM TO"
end

if opts.help?
  puts opts
  exit(0)
end

client = Client.new(opts[:url], opts[:api_key])

case opts.arguments.first
when 'get'
  pp client.get(opts.arguments.drop(1))
when 'get-project'
  pp client.get_project(opts.arguments.fetch(1).split(","), opts.arguments.drop(2))
when 'convert-fiat'
  ticker = opts.arguments.fetch(1)
  target_fiat = opts.arguments.fetch(2)
  rate = client.convert_to_fiat(ticker, target_fiat)
  puts "1 #{ticker} = #{rate.to_f} #{target_fiat}"
when 'exchange'
  from = opts.arguments.fetch(1)
  to = opts.arguments.fetch(2)
  exch = client.exchange_rate(from, to)
  puts "1 #{from} = #{exch.to_f} #{to}"
when nil
  puts "Please specify a command to use"
else
  puts "Unknown command"
  puts opts
end
