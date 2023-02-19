# frozen_string_literal: true

module Arke::Plugin
  # Base class for all plugins
  class Base
    attr_reader :logger, :name

    def initialize(id, params)
      @logger = Arke::Log
      @id = id
      check_config(params)
      @logger.info { "PLUGIN:#{@id} is activated" }
    end

    def check_config(params)
      raise "check_config is not implemented"
    end

    # Initialize limits
    # If balance percentage or quote currency limits were not specified we apply balance percentage with 100% of balance
    def self.init_limits(target, source, params)
      if !params["balance_base_perc"].nil? && !params["balance_quote_perc"].nil?
        return {
          target_limit: Arke::Plugin::BalancePercentage.new(target.account, target.base, target.quote, params),
          source_limit: Arke::Plugin::BalancePercentage.new(source.account, source.base, source.quote, params)
        }
      elsif !params["limit_asks_quote"].nil? && !params["limit_bids_quote"].nil?
        return {
          target_limit: Arke::Plugin::QuoteBalance.new(target.account, target.base, target.quote, params),
          source_limit: Arke::Plugin::QuoteBalance.new(source.account, source.base, source.quote, params)
        }
      else
        return {
          target_limit: Arke::Plugin::BalancePercentage.new(target.account, target.base, target.quote, params),
          source_limit: Arke::Plugin::BalancePercentage.new(source.account, source.base, source.quote, params)
        }
      end
    end
  end
end
