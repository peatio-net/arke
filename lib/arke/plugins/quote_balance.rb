# frozen_string_literal: true

module Arke::Plugin
  class QuoteBalance < Base
    attr_accessor :account, :base, :quote, :limit_asks_quote, :limit_bids_quote

    def initialize(account, base, quote, params)
      @account = account
      @base = base
      @quote = quote
      @limit_asks_quote = params["limit_asks_quote"]&.to_d
      @limit_bids_quote = params["limit_bids_quote"]&.to_d

      super("Quote Balance Limit plugin (#{@account.id})", params)
    end

    def check_config(params)
      if @limit_asks_quote.nil?
        raise "limit_asks_quote must be specified"
      else
        raise "limit_asks_quote must be higher than 0" if  @limit_asks_quote <= 0
      end

      if @limit_bids_quote.nil?
        raise "limit_bids_quote must be specified"
      else
        raise "limit_bids_quote must be higher than 0" if @limit_bids_quote <= 0
      end
    end

    def call(orderbook)
      top_ask = orderbook[:sell].first
      top_bid = orderbook[:buy].first
      raise "Source order book is empty" if top_ask.nil? || top_bid.nil?

      top_ask_price = top_ask.first
      top_bid_price = top_bid.first
      mid_price = (top_ask_price + top_bid_price) / 2

      quote_balance = @account.balance(@quote)["total"]
      base_balance = @account.balance(@base)["total"]
      limit_in_quote = quote_balance
      limit_in_base = base_balance

      # Adjust bids/asks limit with specified limits.
      if @limit_asks_quote < base_balance * mid_price
        limit_in_base = @limit_asks_quote / mid_price
      end

      if @limit_bids_quote < quote_balance
        limit_in_quote = @limit_bids_quote
      end

      {
        mid_price: mid_price,
        top_bid_price: top_bid_price,
        top_ask_price: top_ask_price,
        limit_in_base: limit_in_base,
        limit_in_quote: limit_in_quote,
      }
    end
  end
end
