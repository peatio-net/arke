module Arke
  Trade = Struct.new(:market, :type, :volume, :price, :order_id)
end

require "json"
require "yaml"
require "rbtree"
require "openssl"
require "ostruct"
require "colorize"

require "faraday"
require "faraday_middleware"

require "em-synchrony"
require "em-synchrony/em-http"

require "faye/websocket"

require "binance"
require "bitx"

require "arke/helpers/precision"
require "arke/helpers/commands"
require "arke/helpers/splitter"
require "arke/helpers/spread"

require "arke/configuration"
require "arke/log"
require "arke/reactor"
require "arke/exchange"
require "arke/strategy"
require "arke/action"
require "arke/order"
require "arke/action_executor"
require "arke/action_scheduler"

require "arke/orderbook/base"
require "arke/orderbook/orderbook"
require "arke/orderbook/aggregated"
require "arke/orderbook/open_orders"

require "arke/strategy/base"
require "arke/strategy/copy"
require "arke/strategy/fixedprice"
require "arke/strategy/microtrades"
require "arke/strategy/strategy1"
require "arke/strategy/example1"

require "arke/exchange/base"
require "arke/exchange/binance"
require "arke/exchange/bitfaker"
require "arke/exchange/bitfinex"
require "arke/exchange/hitbtc"
require "arke/exchange/huobi"
require "arke/exchange/kraken"
require "arke/exchange/luno"
require "arke/exchange/okex"
require "arke/exchange/rubykube"
