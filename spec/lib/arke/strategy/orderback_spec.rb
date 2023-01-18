# frozen_string_literal: true


describe Arke::Strategy::Orderback do
  let!(:strategy) { Arke::Strategy::Orderback.new([source], target, config, nil) }
  let(:account) { Arke::Exchange.create(account_config) }
  let(:source) { Arke::Market.new(config["sources"].first["market_id"], account, Arke::Helpers::Flags::DEFAULT_SOURCE_FLAGS) }
  let(:target) { Arke::Market.new(config["target"]["market_id"], account, Arke::Helpers::Flags::DEFAULT_TARGET_FLAGS) }
  let(:side) { "both" }
  let(:spread_asks) { 0.01 }
  let(:spread_bids) { 0.02 }
  let(:level_size) { 0.01 }
  let(:level_count) { 5 }
  let(:orderback_grace_time) { nil }
  let(:orderback_type) { nil }
  let(:enable_orderback) { "true" }
  let(:apply_safe_limits_on_source) { "true" }
  let(:fx_config) { nil }
  let(:balance_base_perc) { nil }
  let(:balance_quote_perc) { nil }
  let(:limit_asks_quote) { nil }
  let(:limit_bids_quote) { nil }

  let(:config) do
    {
      "id"      => "orderback-BTCUSD",
      "type"    => "orderback",
      "debug" => true,
      "params"  => {
        "spread_bids"           => spread_bids,
        "spread_asks"           => spread_asks,
        "levels_algo"           => "constant",
        "levels_size"           => level_size,
        "levels_count"          => level_count,
        "side"                  => side,
        "min_order_back_amount" => 0.001,
        "orderback_grace_time"  => orderback_grace_time,
        "orderback_type"        => orderback_type,
        "enable_orderback"      => enable_orderback,
        "apply_safe_limits_on_source" => apply_safe_limits_on_source,
        "balance_base_perc" => balance_base_perc,
        "balance_quote_perc" => balance_quote_perc,
        "limit_asks_quote" => limit_asks_quote,
        "limit_bids_quote" => limit_bids_quote,
      },
      "fx"      => fx_config,
      "target"  => {
        "account_id" => 1,
        "market_id"  => "BTCUSD",
      },
      "sources" => [
        "account_id" => 1,
        "market_id"  => "xbtusd",
      ],
    }
  end

  let(:account_config) do
    {
      "id"     => 1,
      "driver" => "bitfaker",
    }
  end
  let(:target_orderbook) { strategy.call }
  let(:target_bids) { target_orderbook.first[:buy] }
  let(:target_asks) { target_orderbook.first[:sell] }

  before(:each) do
    source.fetch_balances
    target.fetch_balances
    source.start
    source.update_orderbook
  end

  context "running both sides" do
    let(:side) { "both" }
    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq(
        "135.9554".to_d => "0.2196435728585954911e3".to_d,
        "135.9652".to_d => "0.12064038332490535253e4".to_d,
        "135.9750".to_d => "0.25887541608969201184e4".to_d,
        "135.9848".to_d => "0.39534103098163002607e4".to_d,
        "136.0044".to_d => "0.263572287430314589336e5".to_d,
      )
      expect(target_asks.to_hash).to eq(
        "0.1402573826086956521e3".to_d             => "0.228316045822963728137e5".to_d,
        "140.2688".to_d                            => "0.992678460099842296e2".to_d,
        "140.2789".to_d                            => "0.992678460099842296e2".to_d,
        "140.2890".to_d                            => "0.82910371322311672223e4".to_d,
        "0.1402977264909e3".to_d                   => "0.29780353802995268887e4".to_d
      )
    end
  end

  context "limits from plugin" do
    let(:source_account) { Arke::Exchange.create(source_config) }
    let(:target_account) { Arke::Exchange.create(target_config) }
    let(:source) { Arke::Market.new(config["sources"].first["market_id"], source_account, Arke::Helpers::Flags::DEFAULT_SOURCE_FLAGS) }
    let(:target) { Arke::Market.new(config["target"]["market_id"], target_account, Arke::Helpers::Flags::DEFAULT_TARGET_FLAGS) }
    let(:source_config) do
      {
        "id"     => 1,
        "driver" => "bitfaker",
        "orderbook" => orderbook,
        "params" => {
          "balances" => [
            {
              "currency" => "btc",
              "total"    => source_base_balance,
              "free"     => source_base_balance,
              "locked"   => 0
            },
            {
              "currency" => "usd",
              "total"    => source_quote_balance,
              "free"     => source_quote_balance,
              "locked"   => 0
            }
          ]
        }
      }
    end
    let(:source_base_balance) { 1 }
    let(:source_quote_balance) { 3_000 }

    let(:target_config) do
      {
        "id"     => 2,
        "driver" => "bitfaker",
        "params" => {
          "balances" => [
            {
              "currency" => "BTC",
              "total"    => target_base_balance,
              "free"     => target_base_balance,
              "locked"   => 0.0,
            },
            {
              "currency" => "USD",
              "total"    => target_quote_balance,
              "free"     => target_quote_balance,
              "locked"   => 0.0,
            }
          ],
        }
      }
    end

    let(:level_size) { 1 }
    let(:level_count) { 10 }
    let(:orderbook) do
      [
        nil,
        [
          [1, 10_001, -0.3],
          [2, 10_002, -0.8],
          [3, 10_003, -1.1],
          [4, 10_004, -1.2],
          [5, 10_005, -1.4],
          [6, 10_006, -1.6],
          [7, 10_007, -2.0],
          [8, 10_008, -2.4],
          [9, 10_009, -2.9],
          [10, 10_010, -2.6],
          [11, 10_011, -3.7],
          [12, 9999, 0.2],
          [13, 9998, 0.4],
          [14, 9997, 0.9],
          [15, 9996, 1.4],
          [16, 9995, 1.6],
          [17, 9994, 1.8],
          [18, 9993, 2.0],
          [19, 9992, 2.3],
          [20, 9991, 3.0],
          [21, 9990, 2.7],
          [22, 9989, 3.7],

        ]
      ]
    end

    let(:target_base_balance) { 3 }
    let(:target_quote_balance) { 10_000 }
    let(:source_base_balance) { 2 }
    let(:source_quote_balance) { 3_000 }

    let(:expected_limits) do
      {
        "5_target_asks_base_limit" => 3,
        "5_target_bids_quote_limit" => 10_000,
        "5_source_asks_quote_limit" => 3_000,
        "5_source_bids_base_limit" => 2
      }
    end

    it "for asks limited by source balance Mid price 10_000" do
      target_orderbook = strategy.call

      expect(strategy.debug_infos["6_volume_bids_base"].to_f <= expected_limits["5_source_bids_base_limit"].to_f).to eq(true)
      expect(strategy.debug_infos["5_target_bids_quote_limit"]).to eq(expected_limits["5_target_bids_quote_limit"])
      expect(strategy.debug_infos["5_source_bids_base_limit"]).to eq(expected_limits["5_source_bids_base_limit"])
    end

    it "for bids limited by source balance Mid price 10_000" do
      target_orderbook = strategy.call

      expect(strategy.debug_infos["6_volume_asks_quote"].to_f <= expected_limits["5_source_asks_quote_limit"].to_f).to eq(true)
      expect(strategy.debug_infos["5_target_asks_base_limit"]).to eq(expected_limits["5_target_asks_base_limit"])
      expect(strategy.debug_infos["5_source_asks_quote_limit"]).to eq(expected_limits["5_source_asks_quote_limit"])
    end

    context "for asks and bids limited by source balance in quote Mid price 10_000" do
      let(:source_base_balance) { 4 }
      let(:source_quote_balance) { 20_000 }
      let(:target_base_balance) { 2 }
      let(:target_quote_balance) { 40_000 }

      let(:expected_limits) do
        {
          "5_target_asks_base_limit" => 2,
          "5_target_bids_quote_limit" => 40_000,
          "5_source_asks_quote_limit" => 20_000,
          "5_source_bids_base_limit" => 4
        }
      end

      it "for bids" do
        target_orderbook = strategy.call

        expect(strategy.debug_infos["6_volume_bids_base"].to_f <= expected_limits["5_source_bids_base_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["5_target_bids_quote_limit"]).to eq(expected_limits["5_target_bids_quote_limit"])
        expect(strategy.debug_infos["5_source_bids_base_limit"]).to eq(expected_limits["5_source_bids_base_limit"])
      end

      it "for asks" do
        target_orderbook = strategy.call

        expect(strategy.debug_infos["6_volume_asks_quote"].to_f <= expected_limits["5_source_asks_quote_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["5_target_asks_base_limit"]).to eq(expected_limits["5_target_asks_base_limit"])
        expect(strategy.debug_infos["5_source_asks_quote_limit"]).to eq(expected_limits["5_source_asks_quote_limit"])
      end
    end

    context "for asks and bids limited by source balance in base Mid price 10_000" do
      let(:source_base_balance) { 4 }
      let(:source_quote_balance) { 60_000 }
      let(:target_base_balance) { 6 }
      let(:target_quote_balance) { 40_000 }

      let(:expected_limits) do
        {
          "5_target_asks_base_limit" => 6,
          "5_target_bids_quote_limit" => 40_000,
          "5_source_asks_quote_limit" => 60_000,
          "5_source_bids_base_limit" => 4
        }
      end

      it "for bids" do
        target_orderbook = strategy.call

        expect(strategy.debug_infos["6_volume_bids_base"].to_f <= expected_limits["5_source_bids_base_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["5_target_bids_quote_limit"]).to eq(expected_limits["5_target_bids_quote_limit"])
        expect(strategy.debug_infos["5_source_bids_base_limit"]).to eq(expected_limits["5_source_bids_base_limit"])
      end

      it "for asks" do
        target_orderbook = strategy.call

        expect(strategy.debug_infos["6_volume_asks_quote"].to_f <= expected_limits["5_source_asks_quote_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["5_target_asks_base_limit"]).to eq(expected_limits["5_target_asks_base_limit"])
        expect(strategy.debug_infos["5_source_asks_quote_limit"]).to eq(expected_limits["5_source_asks_quote_limit"])
      end
    end

    context "for asks and bids limited by target balance in base Mid price 10_000" do
      let(:source_base_balance) { 6 }
      let(:source_quote_balance) { 60_000 }
      let(:target_base_balance) { 4 }
      let(:target_quote_balance) { 40_000 }

      let(:expected_limits) do
        {
          "5_target_asks_base_limit" => 4,
          "5_target_bids_quote_limit" => 40_000,
          "5_source_asks_quote_limit" => 60_000,
          "5_source_bids_base_limit" => 6
        }
      end

      it "for bids" do
        target_orderbook = strategy.call

        expect(strategy.debug_infos["6_volume_bids_quote"].to_f <= expected_limits["5_target_bids_quote_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["6_volume_bids_base"].to_f <= expected_limits["5_source_bids_base_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["5_target_bids_quote_limit"]).to eq(expected_limits["5_target_bids_quote_limit"])
        expect(strategy.debug_infos["5_source_bids_base_limit"]).to eq(expected_limits["5_source_bids_base_limit"])
      end

      it "for asks" do
        target_orderbook = strategy.call

        expect(strategy.debug_infos["6_volume_asks_base"].to_f <= expected_limits["5_target_asks_base_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["6_volume_asks_quote"].to_f <= expected_limits["5_source_asks_quote_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["5_target_asks_base_limit"]).to eq(expected_limits["5_target_asks_base_limit"])
        expect(strategy.debug_infos["5_source_asks_quote_limit"]).to eq(expected_limits["5_source_asks_quote_limit"])
      end
    end

    context "for asks and bids with balance percentage and with limit for source balance. Mid price 10_000" do
      let(:balance_base_perc) { 1 }
      let(:balance_quote_perc) { 0.2 }
      let(:source_base_balance) { 2 }
      let(:source_quote_balance) { 20_000 }
      let(:target_base_balance) { 4 }
      let(:target_quote_balance) { 40_000 }

      let(:expected_limits) do
        {
          "5_target_asks_base_limit" => 4,
          "5_target_bids_quote_limit" => 8_000,
          "5_source_asks_quote_limit" => 4_000,
          "5_source_bids_base_limit" => 2
        }
      end

      it "for bids" do
        target_orderbook = strategy.call

        expect(strategy.debug_infos["6_volume_bids_base"].to_f <= expected_limits["5_source_bids_base_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["5_target_bids_quote_limit"]).to eq(expected_limits["5_target_bids_quote_limit"])
        expect(strategy.debug_infos["5_source_bids_base_limit"]).to eq(expected_limits["5_source_bids_base_limit"])
      end

      it "for asks" do
        target_orderbook = strategy.call

        expect(strategy.debug_infos["6_volume_asks_quote"].to_f <= expected_limits["5_source_asks_quote_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["5_target_asks_base_limit"]).to eq(expected_limits["5_target_asks_base_limit"])
        expect(strategy.debug_infos["5_source_asks_quote_limit"]).to eq(expected_limits["5_source_asks_quote_limit"])
      end
    end

    context "for asks and bids with balance percantage and with limit for target balance. Mid price 10_000" do
      let(:balance_base_perc) { 0.5 }
      let(:balance_quote_perc) { 0.5 }
      let(:source_base_balance) { 4 }
      let(:source_quote_balance) { 40_000 }
      let(:target_base_balance) { 2 }
      let(:target_quote_balance) { 20_000 }

      let(:expected_limits) do
        {
          "5_target_asks_base_limit" => 1,
          "5_target_bids_quote_limit" => 10_000,
          "5_source_asks_quote_limit" => 20_000,
          "5_source_bids_base_limit" => 2
        }
      end

      it "for bids" do
        target_orderbook = strategy.call

        expect(strategy.debug_infos["6_volume_bids_quote"].to_f <= expected_limits["5_target_bids_quote_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["6_volume_bids_base"].to_f <= expected_limits["5_source_bids_base_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["5_target_bids_quote_limit"]).to eq(expected_limits["5_target_bids_quote_limit"])
        expect(strategy.debug_infos["5_source_bids_base_limit"]).to eq(expected_limits["5_source_bids_base_limit"])
      end

      it "for asks" do
        target_orderbook = strategy.call

        expect(strategy.debug_infos["6_volume_asks_base"].to_f <= expected_limits["5_target_asks_base_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["6_volume_asks_quote"].to_f <= expected_limits["5_source_asks_quote_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["5_target_asks_base_limit"]).to eq(expected_limits["5_target_asks_base_limit"])
        expect(strategy.debug_infos["5_source_asks_quote_limit"]).to eq(expected_limits["5_source_asks_quote_limit"])
      end
    end

    context "for asks and bids with balance on target and source bigger than orderbook volume. Mid price 10_000" do
      let(:balance_base_perc) { 1 }
      let(:balance_quote_perc) { 1 }
      let(:source_base_balance) { 30 }
      let(:source_quote_balance) { 320_000 }
      let(:target_base_balance) { 24 }
      let(:target_quote_balance) { 300_000 }

      let(:expected_limits) do
        {
          "5_target_asks_base_limit" => 24,
          "5_target_bids_quote_limit" => 300_000,
          "5_source_asks_quote_limit" => 320_000,
          "5_source_bids_base_limit" => 30
        }
      end

      let(:source_orderbook_bids_volume) {
        sum_base = 0.0.to_d
        sum_quote = 0.0.to_d
        orderbook[1].each do |point|
          sum_base += point[2] if point[2] > 0
          sum_quote += point[2] * point[1] if point[2] > 0
        end
        return sum_base, sum_quote
      }

      let(:source_orderbook_asks_volume) {
        sum_base = 0.0.to_d
        sum_quote = 0.0.to_d
        orderbook[1].each do |point|
          sum_base += point[2].abs if point[2] < 0
          sum_quote += point[2].abs * point[1] if point[2] < 0
        end
        return sum_base, sum_quote
      }

      it "for bids" do
        target_orderbook = strategy.call

        bids_base, bids_quote = source_orderbook_bids_volume
        expect(strategy.debug_infos["6_volume_bids_quote"].to_f > bids_quote.to_f).to eq(true)
        expect(strategy.debug_infos["6_volume_bids_base"].to_f > bids_base.to_f).to eq(true)

        expect(strategy.debug_infos["6_volume_bids_quote"].to_f <= expected_limits["5_target_bids_quote_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["6_volume_bids_base"].to_f <= expected_limits["5_source_bids_base_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["5_target_bids_quote_limit"]).to eq(expected_limits["5_target_bids_quote_limit"])
        expect(strategy.debug_infos["5_source_bids_base_limit"]).to eq(expected_limits["5_source_bids_base_limit"])
      end

      it "for asks" do
        target_orderbook = strategy.call

        asks_base, asks_quote = source_orderbook_asks_volume
        expect(strategy.debug_infos["6_volume_asks_quote"].to_f > asks_quote.to_f).to eq(true)
        expect(strategy.debug_infos["6_volume_asks_base"].to_f > asks_base.to_f).to eq(true)

        expect(strategy.debug_infos["6_volume_asks_base"].to_f <= expected_limits["5_target_asks_base_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["6_volume_asks_quote"].to_f <= expected_limits["5_source_asks_quote_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["5_target_asks_base_limit"]).to eq(expected_limits["5_target_asks_base_limit"])
        expect(strategy.debug_infos["5_source_asks_quote_limit"]).to eq(expected_limits["5_source_asks_quote_limit"])
      end
    end

    context "for asks and bids with quote limit less than balance on target and source. Mid price 10_000" do
      let(:limit_asks_quote) { 5000 }
      let(:limit_bids_quote) { 5000 }
      let(:source_base_balance) { 2 }
      let(:source_quote_balance) { 10000 }
      let(:target_base_balance) { 3 }
      let(:target_quote_balance) { 15000 }

      let(:expected_limits) do
        {
          "5_target_asks_base_limit" => 0.5,
          "5_target_bids_quote_limit" => 5000,
          "5_source_asks_quote_limit" => 5000,
          "5_source_bids_base_limit" => 0.5
        }
      end

      let(:source_orderbook_bids_volume) {
        sum_base = 0.0.to_d
        sum_quote = 0.0.to_d
        orderbook[1].each do |point|
          sum_base += point[2] if point[2] > 0
          sum_quote += point[2] * point[1] if point[2] > 0
        end
        return sum_base, sum_quote
      }

      let(:source_orderbook_asks_volume) {
        sum_base = 0.0.to_d
        sum_quote = 0.0.to_d
        orderbook[1].each do |point|
          sum_base += point[2].abs if point[2] < 0
          sum_quote += point[2].abs * point[1] if point[2] < 0
        end
        return sum_base, sum_quote
      }

      it "for bids" do
        target_orderbook = strategy.call

        bids_base, bids_quote = source_orderbook_bids_volume
        expect(strategy.debug_infos["6_volume_bids_quote"].to_f < bids_quote.to_f).to eq(true)
        expect(strategy.debug_infos["6_volume_bids_base"].to_f < bids_base.to_f).to eq(true)

        expect(strategy.debug_infos["6_volume_bids_quote"].to_f <= expected_limits["5_target_bids_quote_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["6_volume_bids_base"].to_f <= expected_limits["5_source_bids_base_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["5_target_bids_quote_limit"]).to eq(expected_limits["5_target_bids_quote_limit"])
        expect(strategy.debug_infos["5_source_bids_base_limit"]).to eq(expected_limits["5_source_bids_base_limit"])
      end

      it "for asks" do
        target_orderbook = strategy.call

        asks_base, asks_quote = source_orderbook_asks_volume
        expect(strategy.debug_infos["6_volume_asks_quote"].to_f < asks_quote.to_f).to eq(true)
        expect(strategy.debug_infos["6_volume_asks_base"].to_f < asks_base.to_f).to eq(true)

        expect(strategy.debug_infos["6_volume_asks_base"].to_f <= expected_limits["5_target_asks_base_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["6_volume_asks_quote"].to_f <= expected_limits["5_source_asks_quote_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["5_target_asks_base_limit"]).to eq(expected_limits["5_target_asks_base_limit"])
        expect(strategy.debug_infos["5_source_asks_quote_limit"]).to eq(expected_limits["5_source_asks_quote_limit"])
      end
    end

    context "for asks and bids with quote limit less than balance on target. Mid price 10_000" do
      let(:limit_asks_quote) { 10000 }
      let(:limit_bids_quote) { 10000 }
      let(:source_base_balance) { 1.5 }
      let(:source_quote_balance) { 8000 }
      let(:target_base_balance) { 3 }
      let(:target_quote_balance) { 15000 }

      let(:expected_limits) do
        {
          "5_target_asks_base_limit" => 1,
          "5_target_bids_quote_limit" => 10000,
          "5_source_asks_quote_limit" => 8000,
          "5_source_bids_base_limit" => 1
        }
      end

      let(:source_orderbook_bids_volume) {
        sum_base = 0.0.to_d
        sum_quote = 0.0.to_d
        orderbook[1].each do |point|
          sum_base += point[2] if point[2] > 0
          sum_quote += point[2] * point[1] if point[2] > 0
        end
        return sum_base, sum_quote
      }

      let(:source_orderbook_asks_volume) {
        sum_base = 0.0.to_d
        sum_quote = 0.0.to_d
        orderbook[1].each do |point|
          sum_base += point[2].abs if point[2] < 0
          sum_quote += point[2].abs * point[1] if point[2] < 0
        end
        return sum_base, sum_quote
      }

      it "for bids" do
        target_orderbook = strategy.call

        bids_base, bids_quote = source_orderbook_bids_volume
        expect(strategy.debug_infos["6_volume_bids_quote"].to_f < bids_quote.to_f).to eq(true)
        expect(strategy.debug_infos["6_volume_bids_base"].to_f < bids_base.to_f).to eq(true)

        expect(strategy.debug_infos["6_volume_bids_quote"].to_f <= expected_limits["5_target_bids_quote_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["6_volume_bids_base"].to_f <= expected_limits["5_source_bids_base_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["5_target_bids_quote_limit"]).to eq(expected_limits["5_target_bids_quote_limit"])
        expect(strategy.debug_infos["5_source_bids_base_limit"]).to eq(expected_limits["5_source_bids_base_limit"])
      end

      it "for asks" do
        target_orderbook = strategy.call

        asks_base, asks_quote = source_orderbook_asks_volume
        expect(strategy.debug_infos["6_volume_asks_quote"].to_f < asks_quote.to_f).to eq(true)
        expect(strategy.debug_infos["6_volume_asks_base"].to_f < asks_base.to_f).to eq(true)

        expect(strategy.debug_infos["6_volume_asks_base"].to_f <= expected_limits["5_target_asks_base_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["6_volume_asks_quote"].to_f <= expected_limits["5_source_asks_quote_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["5_target_asks_base_limit"]).to eq(expected_limits["5_target_asks_base_limit"])
        expect(strategy.debug_infos["5_source_asks_quote_limit"]).to eq(expected_limits["5_source_asks_quote_limit"])
      end
    end

    context "for asks and bids with quote limit bigger than balances. Mid price 10_000" do
      let(:limit_asks_quote) { 30000 }
      let(:limit_bids_quote) { 30000 }
      let(:source_base_balance) { 1.5 }
      let(:source_quote_balance) { 8000 }
      let(:target_base_balance) { 3 }
      let(:target_quote_balance) { 15000 }

      let(:expected_limits) do
        {
          "5_target_asks_base_limit" => 3,
          "5_target_bids_quote_limit" => 15000,
          "5_source_asks_quote_limit" => 8000,
          "5_source_bids_base_limit" => 1.5
        }
      end

      let(:source_orderbook_bids_volume) {
        sum_base = 0.0.to_d
        sum_quote = 0.0.to_d
        orderbook[1].each do |point|
          sum_base += point[2] if point[2] > 0
          sum_quote += point[2] * point[1] if point[2] > 0
        end
        return sum_base, sum_quote
      }

      let(:source_orderbook_asks_volume) {
        sum_base = 0.0.to_d
        sum_quote = 0.0.to_d
        orderbook[1].each do |point|
          sum_base += point[2].abs if point[2] < 0
          sum_quote += point[2].abs * point[1] if point[2] < 0
        end
        return sum_base, sum_quote
      }

      it "for bids" do
        target_orderbook = strategy.call

        bids_base, bids_quote = source_orderbook_bids_volume

        expect(strategy.debug_infos["6_volume_bids_quote"].to_f < bids_quote.to_f).to eq(true)
        expect(strategy.debug_infos["6_volume_bids_base"].to_f < bids_base.to_f).to eq(true)

        expect(strategy.debug_infos["6_volume_bids_quote"].to_f <= expected_limits["5_target_bids_quote_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["6_volume_bids_base"].to_f <= expected_limits["5_source_bids_base_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["5_target_bids_quote_limit"]).to eq(expected_limits["5_target_bids_quote_limit"])
        expect(strategy.debug_infos["5_source_bids_base_limit"]).to eq(expected_limits["5_source_bids_base_limit"])
      end

      it "for asks" do
        target_orderbook = strategy.call

        asks_base, asks_quote = source_orderbook_asks_volume
        expect(strategy.debug_infos["6_volume_asks_quote"].to_f < asks_quote.to_f).to eq(true)
        expect(strategy.debug_infos["6_volume_asks_base"].to_f < asks_base.to_f).to eq(true)

        expect(strategy.debug_infos["6_volume_asks_base"].to_f <= expected_limits["5_target_asks_base_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["6_volume_asks_quote"].to_f <= expected_limits["5_source_asks_quote_limit"].to_f).to eq(true)
        expect(strategy.debug_infos["5_target_asks_base_limit"]).to eq(expected_limits["5_target_asks_base_limit"])
        expect(strategy.debug_infos["5_source_asks_quote_limit"]).to eq(expected_limits["5_source_asks_quote_limit"])
      end
    end
  end

  context "running asks side only" do
    let(:side) { "asks" }
    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq({})
      expect(target_asks.to_hash).to eq(
        "0.1402573826086956521e3".to_d => "0.228316045822963728137e5".to_d,
        "0.1402688e3".to_d => "0.992678460099842296e2".to_d,
        "0.1402789e3".to_d => "0.992678460099842296e2".to_d,
        "0.140289e3".to_d => "0.82910371322311672223e4".to_d,
        "0.1402977264909e3".to_d => "0.29780353802995268887e4".to_d,
      )
    end
  end

  context "running bids side only" do
    let(:side) { "bids" }
    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq(
        "135.9554".to_d => "0.2196435728585954911e3".to_d,
        "135.9652".to_d => "0.12064038332490535253e4".to_d,
        "135.9750".to_d => "0.25887541608969201184e4".to_d,
        "135.9848".to_d => "0.39534103098163002607e4".to_d,
        "136.0044".to_d => "0.263572287430314589336e5".to_d
      )
      expect(target_asks.to_hash).to eq({})
    end
  end

  context "running both sides with a spread" do
    let(:side) { "both" }
    let(:spread_asks) { 0.01 }
    let(:spread_bids) { 0.02 }

    it "outputs a target orberbook" do
      expect(target_asks.to_hash).to eq(
        "0.1402573826086956521e3".to_d => "0.228316045822963728137e5".to_d,
        "0.1402688e3".to_d             => "0.992678460099842296e2".to_d,
        "0.1402789e3".to_d             => "0.992678460099842296e2".to_d,
        "0.140289e3".to_d              => "0.82910371322311672223e4".to_d,
        "0.1402977264909e3".to_d       => "0.29780353802995268887e4".to_d
      )
      expect(target_bids.to_hash).to eq(
        "135.9554".to_d => "0.2196435728585954911e3".to_d,
        "135.9652".to_d => "0.12064038332490535253e4".to_d,
        "135.9750".to_d => "0.25887541608969201184e4".to_d,
        "135.9848".to_d => "0.39534103098163002607e4".to_d,
        "136.0044".to_d => "0.263572287430314589336e5".to_d
      )
    end
  end

  context "running asks side only" do
    let(:side) { "asks" }
    let(:spread_asks) { 0.01 }
    let(:spread_bids) { 0.02 }

    it "outputs a target orberbook" do
      expect(target_asks.to_hash).to eq(
        "0.1402573826086956521e3".to_d => "0.228316045822963728137e5".to_d,
        "0.1402688e3".to_d             => "0.992678460099842296e2".to_d,
        "0.1402789e3".to_d             => "0.992678460099842296e2".to_d,
        "0.140289e3".to_d              => "0.82910371322311672223e4".to_d,
        "0.1402977264909e3".to_d       => "0.29780353802995268887e4".to_d
      )
      expect(target_bids.to_hash).to eq({})
    end
  end

  context "running bids side only" do
    let(:side) { "bids" }
    let(:spread_asks) { 0.01 }
    let(:spread_bids) { 0.02 }

    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq(
        "135.9554".to_d => "0.2196435728585954911e3".to_d,
        "135.9652".to_d => "0.12064038332490535253e4".to_d,
        "135.9750".to_d => "0.25887541608969201184e4".to_d,
        "135.9848".to_d => "0.39534103098163002607e4".to_d,
        "136.0044".to_d => "0.263572287430314589336e5".to_d
      )

      expect(target_asks.to_hash).to eq({})
    end
  end

  context "callback method is functioning" do
    it "registers a callback" do
      expect(target.account.instance_variable_get(:@private_trades_cb).length).to eq(1)
    end
  end

  context "group_trades helper" do
    it "groups trades by price" do
      trades = {
        1 => {41 => ["ABC", 123.0, 10, :buy]},
        2 => {61 => ["ABC", 123.5, 20, :buy]},
        3 => {51 => ["ABC", 123.0, 15, :sell]},
        4 => {51 => ["ABC", 123.0, 15, :buy]},
      }
      expect(strategy.group_trades(trades)).to eq(
        [123.0, :buy]  => 25,
        [123.5, :buy]  => 20,
        [123.0, :sell] => 15
      )
    end
  end

  context "notify_private_trade" do
    let(:orderback_grace_time) { 0.002 }

    it "triggers a buy back to the source market" do
      order = ::Arke::Order.new("BTCUSD", 139.45, 1, :sell, "limit", 14)
      target.add_order(order)
      trade = ::Arke::Trade.new(42, "BTCUSD", nil, 0.5, 139.45, 69.725, 14)
      source.account.executor = double(:executor)

      orderb = ::Arke::Order.new("xbtusd", 138.069306, 0.5, :buy, "market")
      actions = [
        ::Arke::Action.new(:order_create, source, order: orderb)
      ]
      expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
      EM.synchrony do
        strategy.notify_private_trade(trade)
        EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
      end
    end

    it "triggers a sell back to the source market" do
      order = ::Arke::Order.new("BTCUSD", 98, 1, :buy, "limit", 14)
      target.add_order(order)
      trade = ::Arke::Trade.new(42, "BTCUSD", nil, 0.5, 98, 49, 14)
      source.account.executor = double(:executor)

      orderb = ::Arke::Order.new("xbtusd", 100, 0.5, :sell, "market")
      actions = [
        ::Arke::Action.new(:order_create, source, order: orderb)
      ]
      expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
      EM.synchrony do
        strategy.notify_private_trade(trade)
        EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
      end
    end
  end

  context "notify_private_trade called several times with trades of the same price" do
    let(:orderback_grace_time) { 0.002 }

    it "triggers one order back to the source market" do
      order = ::Arke::Order.new("BTCUSD", 139.45, 1, :sell, "limit", 14)
      target.add_order(order)
      trade1 = ::Arke::Trade.new(42, "BTCUSD", nil, 0.1, 139.45, nil, 14)
      trade2 = ::Arke::Trade.new(43, "BTCUSD", nil, 0.2, 139.45, nil, 14)
      trade3 = ::Arke::Trade.new(44, "BTCUSD", nil, 0.3, 139.45, nil, 14)

      orderb = ::Arke::Order.new("xbtusd", 138.069306, 0.6, :buy, "market")
      actions = [
        ::Arke::Action.new(:order_create, source, order: orderb)
      ]
      source.account.executor = double(:executor)
      expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
      EM.synchrony do
        strategy.notify_private_trade(trade1)
        strategy.notify_private_trade(trade2)
        strategy.notify_private_trade(trade3)
        EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
      end
    end
  end

  context "notify_private_trade called several times with trades of different prices" do
    let(:orderback_grace_time) { 0.01 }

    it "triggers several orders back to the source" do
      order1 = ::Arke::Order.new("BTCUSD", 139.45, 1, :sell, "limit", 14)
      order2 = ::Arke::Order.new("BTCUSD", 140.00, 1, :sell, "limit", 15)
      target.add_order(order1)
      target.add_order(order2)

      trade1 = ::Arke::Trade.new(42, "BTCUSD", nil, 0.1, 139.45, nil, 14)
      trade2 = ::Arke::Trade.new(43, "BTCUSD", nil, 0.2, 139.45, nil, 14)
      trade3 = ::Arke::Trade.new(44, "BTCUSD", nil, 0.3, 140.00, nil, 15)

      orderb1 = ::Arke::Order.new("xbtusd", 138.069306, 0.3, :buy, "market")
      orderb2 = ::Arke::Order.new("xbtusd", 138.613861, 0.3, :buy, "market")
      actions = [
        ::Arke::Action.new(:order_create, source, order: orderb1),
        ::Arke::Action.new(:order_create, source, order: orderb2)
      ]
      source.account.executor = double(:executor)
      expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
      EM.synchrony do
        strategy.notify_private_trade(trade1)
        strategy.notify_private_trade(trade2)
        strategy.notify_private_trade(trade3)
        EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
      end
    end
  end

  context "notify_private_trade called several times with trades of same price but different orders" do
    let(:orderback_grace_time) { 0.01 }

    it "triggers several orders back to the source" do
      order1 = ::Arke::Order.new("BTCUSD", 139.45, 1, :sell, "limit", 14)
      order2 = ::Arke::Order.new("BTCUSD", 139.45, 1, :sell, "limit", 15)
      target.add_order(order1)
      target.add_order(order2)

      trade1 = ::Arke::Trade.new(42, "BTCUSD", nil, 0.1, 139.45, nil, 14)
      trade2 = ::Arke::Trade.new(43, "BTCUSD", nil, 0.2, 139.45, nil, 14)
      trade3 = ::Arke::Trade.new(44, "BTCUSD", nil, 0.3, 139.45, nil, 15)

      orderb = ::Arke::Order.new("xbtusd", 138.069306, 0.6, :buy, "market")
      actions = [
        ::Arke::Action.new(:order_create, source, order: orderb)
      ]
      source.account.executor = double(:executor)
      expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
      EM.synchrony do
        strategy.notify_private_trade(trade1)
        strategy.notify_private_trade(trade2)
        strategy.notify_private_trade(trade3)
        EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
      end
    end
  end

  context "fx rate applied from the source prices" do
    let(:fx_config) do
      {
        "type" => "static",
        "rate" => 0.5,
      }
    end

    before(:each) do
      if config["fx"]
        type = config["fx"]["type"]
        fx_klass = Arke::Fx.const_get(type.capitalize)
        strategy.fx = fx_klass.new(config["fx"])
      end
    end

    context "notify_private_trade" do
      let(:orderback_grace_time) { 0.002 }

      it "triggers a buy back to the source market" do
        order = ::Arke::Order.new("BTCUSD", 101, 1, :sell, "limit", 14)
        target.add_order(order)
        trade = ::Arke::Trade.new(42, "BTCUSD", nil, 0.5, 101, 50.50, 14)
        source.account.executor = double(:executor)

        orderb = ::Arke::Order.new("xbtusd", 200, 0.5, :buy, "market")
        actions = [
          ::Arke::Action.new(:order_create, source, order: orderb)
        ]
        expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
        EM.synchrony do
          strategy.notify_private_trade(trade)
          EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
        end
      end

      it "triggers a sell back to the source market" do
        order = ::Arke::Order.new("BTCUSD", 98, 1, :buy, "limit", 14)
        target.add_order(order)
        trade = ::Arke::Trade.new(42, "BTCUSD", nil, 0.5, 98, 49, 14)
        source.account.executor = double(:executor)

        orderb = ::Arke::Order.new("xbtusd", 200, 0.5, :sell, "market")
        actions = [
          ::Arke::Action.new(:order_create, source, order: orderb)
        ]
        expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
        EM.synchrony do
          strategy.notify_private_trade(trade)
          EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
        end
      end
    end

    context "notify_private_trade with a different price from the order" do
      let(:orderback_grace_time) { 0.002 }

      it "triggers a buy back to the source market" do
        order = ::Arke::Order.new("BTCUSD", 101, 1, :sell, "limit", 14)
        target.add_order(order)
        trade = ::Arke::Trade.new(42, "BTCUSD", nil, 0.5, 102, 51, 14)
        source.account.executor = double(:executor)

        orderb = ::Arke::Order.new("xbtusd", 200, 0.5, :buy, "market")
        actions = [
          ::Arke::Action.new(:order_create, source, order: orderb)
        ]
        expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
        EM.synchrony do
          strategy.notify_private_trade(trade)
          EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
        end
      end
    end

    context "notify_private_trade called several times with trades of the same price" do
      let(:orderback_grace_time) { 0.002 }

      it "triggers one order back to the source market" do
        order = ::Arke::Order.new("BTCUSD", 101, 1, :sell, "limit", 14)
        target.add_order(order)
        trade1 = ::Arke::Trade.new(42, "BTCUSD", nil, 0.1, 101, nil, 14)
        trade2 = ::Arke::Trade.new(43, "BTCUSD", nil, 0.2, 101, nil, 14)
        trade3 = ::Arke::Trade.new(44, "BTCUSD", nil, 0.3, 101, nil, 14)

        orderb = ::Arke::Order.new("xbtusd", 200, 0.6, :buy, "market")
        actions = [
          ::Arke::Action.new(:order_create, source, order: orderb)
        ]
        source.account.executor = double(:executor)
        expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
        EM.synchrony do
          strategy.notify_private_trade(trade1)
          strategy.notify_private_trade(trade2)
          strategy.notify_private_trade(trade3)
          EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
        end
      end
    end

    context "notify_private_trade called several times with trades of different prices" do
      let(:orderback_grace_time) { 0.01 }

      it "triggers several orders back to the source" do
        order1 = ::Arke::Order.new("BTCUSD", 101, 1, :sell, "limit", 14)
        order2 = ::Arke::Order.new("BTCUSD", 106.05, 1, :sell, "limit", 15)
        target.add_order(order1)
        target.add_order(order2)

        trade1 = ::Arke::Trade.new(42, "BTCUSD", nil, 0.1, 101, nil, 14)
        trade2 = ::Arke::Trade.new(43, "BTCUSD", nil, 0.2, 101, nil, 14)
        trade3 = ::Arke::Trade.new(44, "BTCUSD", nil, 0.3, 106.05, nil, 15)

        orderb1 = ::Arke::Order.new("xbtusd", 200, 0.3, :buy, "market")
        orderb2 = ::Arke::Order.new("xbtusd", 210, 0.3, :buy, "market")
        actions = [
          ::Arke::Action.new(:order_create, source, order: orderb1),
          ::Arke::Action.new(:order_create, source, order: orderb2)
        ]
        source.account.executor = double(:executor)
        expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
        EM.synchrony do
          strategy.notify_private_trade(trade1)
          strategy.notify_private_trade(trade2)
          strategy.notify_private_trade(trade3)
          EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
        end
      end
    end

    context "notify_private_trade called several times with trades of same price but different orders" do
      let(:orderback_grace_time) { 0.01 }

      it "triggers several orders back to the source" do
        order1 = ::Arke::Order.new("BTCUSD", 101, 1, :sell, "limit", 14)
        order2 = ::Arke::Order.new("BTCUSD", 101, 1, :sell, "limit", 15)
        target.add_order(order1)
        target.add_order(order2)

        trade1 = ::Arke::Trade.new(42, "BTCUSD", nil, 0.1, 101, nil, 14)
        trade2 = ::Arke::Trade.new(43, "BTCUSD", nil, 0.2, 101, nil, 14)
        trade3 = ::Arke::Trade.new(44, "BTCUSD", nil, 0.3, 101, nil, 15)

        orderb = ::Arke::Order.new("xbtusd", 200, 0.6, :buy, "market")
        actions = [
          ::Arke::Action.new(:order_create, source, order: orderb)
        ]
        source.account.executor = double(:executor)
        expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
        EM.synchrony do
          strategy.notify_private_trade(trade1)
          strategy.notify_private_trade(trade2)
          strategy.notify_private_trade(trade3)
          EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
        end
      end
    end

    context "notify_private_trade called several times with trades of same order price but different orders" do
      let(:orderback_grace_time) { 0.01 }

      it "triggers several orders back to the source" do
        order1 = ::Arke::Order.new("BTCUSD", 101, 1, :sell, "limit", 14)
        order2 = ::Arke::Order.new("BTCUSD", 101, 1, :sell, "limit", 15)
        target.add_order(order1)
        target.add_order(order2)

        trade1 = ::Arke::Trade.new(42, "BTCUSD", nil, 0.1, 101, nil, 14)
        trade2 = ::Arke::Trade.new(43, "BTCUSD", nil, 0.2, 102, nil, 14)
        trade3 = ::Arke::Trade.new(44, "BTCUSD", nil, 0.3, 101, nil, 15)

        orderb = ::Arke::Order.new("xbtusd", 200, 0.6, :buy, "market")
        actions = [
          ::Arke::Action.new(:order_create, source, order: orderb)
        ]
        source.account.executor = double(:executor)
        expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
        EM.synchrony do
          strategy.notify_private_trade(trade1)
          strategy.notify_private_trade(trade2)
          strategy.notify_private_trade(trade3)
          EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
        end
      end
    end

    context "notify_private_trade called while the fx rate is not ready yet" do
      let(:orderback_grace_time) { 0.01 }

      it "triggers several orders back to the source" do
        order1 = ::Arke::Order.new("BTCUSD", 101, 1, :sell, "limit", 14)
        order2 = ::Arke::Order.new("BTCUSD", 101, 1, :sell, "limit", 15)
        target.add_order(order1)
        target.add_order(order2)

        trade1 = ::Arke::Trade.new(42, "BTCUSD", nil, 0.1, 101, nil, 14)
        trade2 = ::Arke::Trade.new(43, "BTCUSD", nil, 0.2, 102, nil, 14)
        trade3 = ::Arke::Trade.new(44, "BTCUSD", nil, 0.3, 101, nil, 15)

        orderb = ::Arke::Order.new("xbtusd", 2000, 0.6, :buy, "market")
        actions = [
          ::Arke::Action.new(:order_create, source, order: orderb)
        ]
        source.account.executor = double(:executor)
        expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)

        EM.synchrony do
          strategy.fx.instance_variable_set(:@rate, nil)

          strategy.notify_private_trade(trade1)
          strategy.notify_private_trade(trade2)
          strategy.notify_private_trade(trade3)
          EM::Synchrony.add_timer(0.5) { strategy.fx.instance_variable_set(:@rate, 0.05) }
          EM::Synchrony.add_timer(1.1) { EM.stop }
        end
      end
    end
  end

  context "orderback_type" do
    let(:orderback_grace_time) { 0.002 }

    def validate_orderback_type(type)
      order = ::Arke::Order.new("BTCUSD", 139.45, 1, :sell, "limit", 14)
      target.add_order(order)
      trade = ::Arke::Trade.new(42, "BTCUSD", nil, 0.5, 139.45, 69.725, 14)
      source.account.executor = double(:executor)

      orderb = ::Arke::Order.new("xbtusd", 138.069306, 0.5, :buy, type)
      actions = [
        ::Arke::Action.new(:order_create, source, order: orderb)
      ]
      expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
      EM.synchrony do
        strategy.notify_private_trade(trade)
        EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
      end
    end

    it "triggers a buy back with `market` order type as default to the source market" do
      validate_orderback_type("market")
    end

    context "orderback_type: limit" do
      let!(:strategy) { Arke::Strategy::Orderback.new([source], target, config.merge("params" => config["params"].merge("orderback_type" => "limit")), nil) }

      it "triggers a buy back with `limit` order type to the source market" do
        validate_orderback_type("limit")
      end
    end

    context "orderback_type: market" do
      let!(:strategy) { Arke::Strategy::Orderback.new([source], target, config.merge("params" => config["params"].merge("orderback_type" => "market")), nil) }

      it "triggers a buy back with `market` order type to the source market" do
        validate_orderback_type("market")
      end
    end

    context "orderback_type: invalid" do
      it "should have the RuntimeError: orderback_type must be `limit` or `market`" do
        expect { Arke::Strategy::Orderback.new([source], target, config.merge("params" => config["params"].merge("orderback_type" => "invalid")), nil) }.to raise_error(RuntimeError, /orderback_type must be `limit` or `market`/)
      end
    end
  end
end
