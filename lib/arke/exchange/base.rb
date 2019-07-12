module Arke::Exchange

  # Base class for all exchanges
  class Base
    include ::Arke::Helpers::Precision

    attr_reader :delay, :open_orders, :market, :driver, :opts
    attr_reader :balances, :base, :quote, :base_precision, :quote_precision
    attr_reader :min_ask_amount, :min_bid_amount, :min_order_back_amount
    attr_accessor :timer

    DefaultDelay = 1
    DefaultBasePrecision = 8
    DefaultQuotePrecision = 8

    def initialize(opts)
      @market = opts["market"]["id"]
      @base = opts["market"]["base"]
      @quote = opts["market"]["quote"]
      @base_precision = opts["market"]["base_precision"] || DefaultBasePrecision
      @quote_precision = opts["market"]["quote_precision"] || DefaultQuotePrecision
      @min_ask_amount = opts["market"]["min_ask_amount"]
      @min_bid_amount = opts["market"]["min_bid_amount"]
      @min_order_back_amount = opts["market"]["min_order_back_amount"].to_f
      @driver = opts["driver"]
      @api_key = opts["key"]
      @secret = opts["secret"]
      @delay = (opts["delay"] || DefaultDelay).to_f
      @adapter = opts[:faraday_adapter] || :em_synchrony
      @opts = opts
      @balances = nil
      @timer = nil
      @open_orders = Arke::Orderbook::OpenOrders.new(@market)
      @orderbook = Arke::Orderbook::Orderbook.new(@market)
      @trades_cb = []
      load_platform_markets(opts["driver"]) if opts[:load_platform_markets]
    end

    def info(msg)
      Arke::Log.info "#{@driver}: #{msg}"
    end

    def to_s
      "Exchange::#{self.class} config: #{@opts}"
    end

    # Registers callbacks on trade event in strategy
    def register_on_trade_cb(&cb)
      @trades_cb << cb
    end

    # Is executed in exchange when trade event is pushed to the websocket
    def notify_trade(trade, order)
      @trades_cb.each { |cb| cb.call(trade, order) }
    end

    def start
      raise "start not implemented"
    end

    def stop
      raise "stop not implemented"
    end

    def create_order(order)
      raise "create_order not implemented"
    end

    def stop_order(order)
      raise "stop_order not implemented"
    end

    def fetch_openorders
      raise "fetch_openorders not implemented"
    end

    def fetch_balances
      balances = get_balances()
      @balances = balances
    end

    def balance(currency)
      return nil unless balances
      balances.find { |b| b["currency"] == currency }
    end

    def build_query(params)
      params.keys.sort.map {|k| "#{Faraday::Utils.escape(k)}=#{Faraday::Utils.escape(params[k])}" }.join('&')
    end

    def print
      return unless @orderbook
      puts "Exchange #{@driver} market: #{@market}"
      puts @orderbook.print(:buy)
      puts @orderbook.print(:sell)
    end

    def build_error(response)
      JSON.parse(response.body)
    rescue StandardError => e
      "Code: #{response.env.status} Message: #{response.env.reason_phrase}"
    end

    def load_platform_markets(platform)
      @platform_markets = PlatformMarket.where(platform: platform).each_with_object({}) { |p, h| h[p.market] = p.id }
    end
  end
end