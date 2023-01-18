# frozen_string_literal: true

module Arke::Plugin
  class BalancePercentage < Base
    attr_accessor :account, :base, :quote, :balance_base_perc, :balance_quote_perc

    def initialize(account, base, quote, params)
      @account = account
      @base = base
      @quote = quote
      @balance_base_perc = params["balance_base_perc"]&.to_d
      @balance_quote_perc = params["balance_quote_perc"]&.to_d

      super("Balance Percentage Limit plugin (#{@account.id})", params)
    end

    def check_config(params)
      if !@balance_base_perc.nil?
        raise "balance_base_perc must be higher than 0 to 1" if  @balance_base_perc <= 0 || @balance_base_perc > 1
      else
        @balance_base_perc = 1
      end
      if !@balance_quote_perc.nil?
        raise "balance_quote_perc must be higher than 0 to 1" if @balance_quote_perc <= 0 || @balance_quote_perc > 1
      else
        @balance_quote_perc = 1
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

      # Adjust bids/asks limit by balance ratio.
      if !@balance_quote_perc.nil? && @balance_quote_perc > 0
        limit_in_quote = quote_balance * @balance_quote_perc
      end
      if !@balance_base_perc.nil? && @balance_base_perc > 0
        limit_in_base = base_balance * @balance_base_perc
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
