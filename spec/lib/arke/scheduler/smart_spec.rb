# frozen_string_literal: true

describe Arke::Scheduler::Smart do
  let(:market) { "ethusd" }
  let(:exchange_config) do
    {
      "driver" => "rubykube",
      "host"   => "http://www.example.com",
      "market" => {
        "id"              => "ETHUSDT",
        "base"            => "ETH",
        "quote"           => "USDT",
        "base_precision"  => 4,
        "quote_precision" => 4,
        "min_ask_amount"  => 0.01,
        "min_bid_amount"  => 0.01,
      },
    }
  end
  let(:opts) do
    {
      price_levels: price_levels,
    }
  end
  let(:action_scheduler) { Arke::Scheduler::Smart.new(current_openorders, desired_orderbook, target, opts) }
  let(:current_openorders) { Arke::Orderbook::OpenOrders.new(market) }
  let(:desired_orderbook) { Arke::Orderbook::Orderbook.new(market) }
  let(:price_levels) do
    {
      asks: [::Arke::PricePoint.new(1.2, 1.1), ::Arke::PricePoint.new(1.5, 1.4)],
      bids: [::Arke::PricePoint.new(0.9, 1.0)],
    }
  end
  let(:target) { Arke::Market.new(exchange_config["market"], Arke::Exchange::Bitfaker.new(exchange_config)) }
  let(:order_buy) { Arke::Order.new(market, 1, 1, :buy, "limit", 9) }
  let(:order_buy2) { Arke::Order.new(market, 0.9, 3, :buy, "limit", 12) }
  let(:order_sell) { Arke::Order.new(market, 1.1, 1, :sell, "limit", 10) }
  let(:order_sell2) { Arke::Order.new(market, 1.4, 1, :sell, "limit", 11) }

  context "current and desired orderbooks are empty" do
    it "creates no action" do
      action_scheduler.schedule
      expect(action_scheduler.actions).to be_empty()
    end
  end

  context "desired orderbook is empty" do
    it "generates stop order action for order buy" do
      current_openorders.add_order(order_buy)
      expect(action_scheduler.schedule).to eq(
        [
          Arke::Action.new(:order_stop, target, order: order_buy, priority: 1050),
        ]
      )
    end

    it "generates two more actions for more orders" do
      current_openorders.add_order(order_sell)
      current_openorders.add_order(order_sell2)
      current_openorders.add_order(order_buy2)
      expect(action_scheduler.schedule).to eq(
        [
          Arke::Action.new(:order_stop, target, id: 12, order: order_buy2, priority: 1052.631579),
          Arke::Action.new(:order_stop, target, id: 10, order: order_sell, priority: 1047.619048),
          Arke::Action.new(:order_stop, target, id: 11, order: order_sell2, priority: 1041.666667),
        ]
      )
    end
  end

  context "current orderbook is empty" do
    it "generates order creation" do
      desired_orderbook.update(order_buy)
      desired_orderbook.update(order_sell)
      expect(action_scheduler.schedule).to eq(
        [
          Arke::Action.new(:order_create, target, order: order_buy, priority: 1100),
          Arke::Action.new(:order_create, target, order: order_sell, priority: 1100),
        ]
      )
    end
  end

  context "current and desired orderbooks aren't empty" do
    it "creates needed orders" do
      current_openorders.add_order(order_buy)
      current_openorders.add_order(order_sell)

      desired_orderbook.update(order_buy)
      desired_orderbook.update(order_sell)
      desired_orderbook.update(order_sell2)
      desired_orderbook.update(order_buy2)

      expect(action_scheduler.schedule).to eq(
        [
          # Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 1, 3, :buy, "limit"), priority: 2750.to_d),
          Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 1.4, 1, :sell, "limit"), priority: 1076.923077),
        ]
      )
    end

    it "stops created order" do
      current_openorders.add_order(order_sell2)
      current_openorders.add_order(order_buy2)
      expect(action_scheduler.schedule).to eq(
        [
          Arke::Action.new(:order_stop, target, id: 12, order: order_buy2, priority: 1052.631579),
          Arke::Action.new(:order_stop, target, id: 11, order: order_sell2, priority: 1041.666667),
        ]
      )
    end

    context "more orders" do
      let(:price_levels) do
        {
          asks: [::Arke::PricePoint.new(1.2, 1.1), ::Arke::PricePoint.new(2.5, 2.2)],
          bids: [::Arke::PricePoint.new(0.95, 1.15), ::Arke::PricePoint.new(0.8, 0.85)],
        }
      end
      it "adjusts levels depending on liquidity needs for each" do
        order_sell_14 = Arke::Order.new(market, 2.0, 1, :sell, "limit", 14)
        order_sell_13 = Arke::Order.new(market, 1.9, 1, :sell, "limit", 13)
        order_buy_10  = Arke::Order.new(market, 1.4, 3, :buy,  "limit", 10)
        order_buy_11  = Arke::Order.new(market, 1,   1, :buy,  "limit", 11)
        order_buy_12  = Arke::Order.new(market, 0.9, 1, :buy,  "limit", 12)

        current_openorders.add_order(order_buy_10)
        current_openorders.add_order(order_buy_11)
        current_openorders.add_order(order_buy_12)
        current_openorders.add_order(order_sell_13)
        current_openorders.add_order(order_sell_14)

        desired_orderbook.update(Arke::Order.new(market, 1.91, 1,  :sell))
        desired_orderbook.update(Arke::Order.new(market, 1.41, 1,  :sell))
        desired_orderbook.update(Arke::Order.new(market, 1.1,  1,  :buy))
        desired_orderbook.update(Arke::Order.new(market, 1.01, 1,  :buy))
        desired_orderbook.update(Arke::Order.new(market, 0.9,  1.5, :buy))

        expect(action_scheduler.schedule).to eq(
          [
            Arke::Action.new(:order_stop, target, order: order_buy_10, priority: 1_000_000_000.3),
            # Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 1.15, 1, :buy), priority: 2000.to_d),
            # Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 0.85, 0.5, :buy), priority: 1333.33.to_d),
          ]
        )
      end
    end

    context "too much liquidity in level" do
      let(:price_levels) do
        {
          asks: [::Arke::PricePoint.new(2.0, 1.95)],
          bids: [::Arke::PricePoint.new(1.0, 1.25)],
        }
      end
      it "adjusts levels depending on liquidity needs for each" do
        order_buy_15  = Arke::Order.new(market, 1.5, 1, :buy,  "limit", 15)
        order_buy_14  = Arke::Order.new(market, 1.4, 1, :buy,  "limit", 14)
        order_buy_13  = Arke::Order.new(market, 1.3, 3, :buy,  "limit", 13)
        order_buy_12  = Arke::Order.new(market, 1.2, 1, :buy,  "limit", 12)
        order_buy_11  = Arke::Order.new(market, 1.1, 1, :buy,  "limit", 11)
        order_buy_10  = Arke::Order.new(market, 1.0, 3, :buy,  "limit", 10)

        current_openorders.add_order(order_buy_10)
        current_openorders.add_order(order_buy_11)
        current_openorders.add_order(order_buy_12)
        current_openorders.add_order(order_buy_13)
        current_openorders.add_order(order_buy_14)
        current_openorders.add_order(order_buy_15)

        desired_orderbook.update(Arke::Order.new(market, 1.5, 5, :buy))

        expect(action_scheduler.schedule).to eq(
          [
            Arke::Action.new(:order_stop, target, order: order_buy_15, priority: 1100),
            Arke::Action.new(:order_stop, target, order: order_buy_14, priority: 1090.909091),
            Arke::Action.new(:order_stop, target, order: order_buy_13, priority: 1083.333333),
            Arke::Action.new(:order_stop, target, order: order_buy_12, priority: 1076.923077),
            Arke::Action.new(:order_stop, target, order: order_buy_11, priority: 1071.428571),
          ]
        )
      end
    end

    context "overlapping orderbooks" do
      let(:price_levels) do
        {
          asks: [::Arke::PricePoint.new(2.5, 2.2), ::Arke::PricePoint.new(3.5, 3.15)],
          bids: [::Arke::PricePoint.new(2.0, 2.1), ::Arke::PricePoint.new(1.0, 1.25)],
        }
      end

      it "stops overlapping orders first (sell overlap buy on market price DUMP)" do
        order_sell = Arke::Order.new(market, 2.0, 1, :sell, "limit", 1)
        order_buy  = Arke::Order.new(market, 1.0, 1, :buy,  "limit", 2)

        current_openorders.add_order(order_buy)
        current_openorders.add_order(order_sell)

        desired_orderbook.update(Arke::Order.new(market, 2.2, 1, :sell))
        desired_orderbook.update(Arke::Order.new(market, 2.1, 1, :buy))

        expect(action_scheduler.schedule).to eq(
          [
            Arke::Action.new(:order_stop, target, order: order_sell, priority: 1_000_000_000.2.to_d),
            Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 2.1, 1, :buy), priority: 1100),
            Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 2.2, 1, :sell), priority: 1100),
            Arke::Action.new(:order_stop, target, order: order_buy, priority: 1047.619048),
          ]
        )
      end

      it "stops overlapping orders first (buy overlap sell on market price PUMP)" do
        order_sell_14 = Arke::Order.new(market, 2.0,  1, :sell, "limit", 14)
        order_sell_13 = Arke::Order.new(market, 1.9,  1, :sell, "limit", 13)
        order_buy_10  = Arke::Order.new(market, 1.4,  3, :buy,  "limit", 10)
        order_buy_11  = Arke::Order.new(market, 1.35, 1, :buy,  "limit", 11)

        current_openorders.add_order(order_buy_10)
        current_openorders.add_order(order_buy_11)
        current_openorders.add_order(order_sell_13)
        current_openorders.add_order(order_sell_14)

        desired_orderbook.update(Arke::Order.new(market, 2.2, 1,  :sell))
        desired_orderbook.update(Arke::Order.new(market, 2.1, 1,  :sell))
        desired_orderbook.update(Arke::Order.new(market, 2.0, 1,  :buy))
        desired_orderbook.update(Arke::Order.new(market, 1.9, 1,  :buy))

        expect(action_scheduler.schedule).to eq(
          [
            Arke::Action.new(:order_stop, target, order: order_sell_13, priority: 1_000_000_000.2),
            Arke::Action.new(:order_stop, target, order: order_sell_14, priority: 1_000_000_000.1),
            Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 2.1, 1, :buy), priority: 1090.909091),
            Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 2.2, 2, :sell), priority: 1090.909091),
            Arke::Action.new(:order_stop, target, order: order_buy_10, priority: 1062.5),
            Arke::Action.new(:order_stop, target, order: order_buy_11, priority: 1060.606061),
          ]
        )
      end

      it "stops overlapping orders first (buy == sell on market price PUMP)" do
        order_sell = Arke::Order.new(market, 2.0, 1, :sell, "limit", 1)
        order_buy = Arke::Order.new(market, 1.0, 1, :buy, "limit", 2)

        current_openorders.add_order(order_buy)
        current_openorders.add_order(order_sell)

        desired_orderbook.update(Arke::Order.new(market, 2.1, 1, :sell))
        desired_orderbook.update(Arke::Order.new(market, 2.0, 1, :buy))

        expect(action_scheduler.schedule).to eq(
          [
            Arke::Action.new(:order_stop, target, order: order_sell, priority: 1_000_000_000.1),
            Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 2.1, 1, :buy), priority: 1090.909091),
            Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 2.2, 1, :sell), priority: 1090.909091),
            Arke::Action.new(:order_stop, target, order: order_buy, priority: 1050),
          ]
        )
      end

      it "stops overlapping orders first (buy == sell on market price DUMP)" do
        order_sell = Arke::Order.new(market, 2.0, 1, :sell, "limit", 1)
        order_buy  = Arke::Order.new(market, 1.0, 1, :buy,  "limit", 2)

        current_openorders.add_order(order_buy)
        current_openorders.add_order(order_sell)

        desired_orderbook.update(Arke::Order.new(market, 1.0, 1, :sell))
        desired_orderbook.update(Arke::Order.new(market, 0.9, 1, :buy))

        expect(action_scheduler.schedule).to eq(
          [
            Arke::Action.new(:order_stop, target, order: order_buy, priority: 1_000_000_000.1.to_d),
          ]
        )
      end
    end

    it "raises error if any ask price is lower than big price" do
      desired_orderbook.update(Arke::Order.new(market, 2.2, 1,  :sell))
      desired_orderbook.update(Arke::Order.new(market, 2.0, 1,  :sell))
      desired_orderbook.update(Arke::Order.new(market, 2.1, 1,  :buy))
      desired_orderbook.update(Arke::Order.new(market, 1.9, 1,  :buy))
      expect { action_scheduler.schedule }.to raise_error(Arke::Scheduler::InvalidOrderBook)
    end
  end

  context "cancel_out_of_boundaries_orders" do
    let(:order_sell_14) { Arke::Order.new(market, 2.0, 1, :sell, "limit", 14) }
    let(:order_sell_13) { Arke::Order.new(market, 1.9, 1, :sell, "limit", 13) }
    let(:order_buy_10)  { Arke::Order.new(market, 1.4, 3, :buy,  "limit", 10) }
    let(:order_buy_11)  { Arke::Order.new(market, 1.0, 1, :buy,  "limit", 11) }
    let(:order_buy_12)  { Arke::Order.new(market, 0.9, 1, :buy,  "limit", 12) }

    before(:each) do
      current_openorders.add_order(order_buy_10)
      current_openorders.add_order(order_buy_11)
      current_openorders.add_order(order_buy_12)
      current_openorders.add_order(order_sell_13)
      current_openorders.add_order(order_sell_14)
    end

    let(:price_levels) do
      {
        asks: [::Arke::PricePoint.new(1.95, 1.9)],
        bids: [::Arke::PricePoint.new(1.10, 1.4)],
      }
    end

    context "low liquidity flag is not raised" do
      it "cancels orders over the bounds with very low priority" do
        expect(action_scheduler.cancel_out_of_boundaries_orders(:sell, price_levels[:asks].last&.price_point, proc { false })).to eq(
          [
            Arke::Action.new(:order_stop, target, order: order_sell_14, priority: 1.05),
          ]
        )
        expect(action_scheduler.cancel_out_of_boundaries_orders(:buy, price_levels[:bids].last&.price_point, proc { false })).to eq(
          [
            Arke::Action.new(:order_stop, target, order: order_buy_11, priority: 1.1),
            Arke::Action.new(:order_stop, target, order: order_buy_12, priority: 1.2),
          ]
        )
      end
    end

    context "low liquidity flag is raised" do
      it "cancels orders over the bounds with high priority" do
        expect(action_scheduler.cancel_out_of_boundaries_orders(:sell, price_levels[:asks].last&.price_point, proc { true })).to eq(
          [
            Arke::Action.new(:order_stop, target, order: order_sell_14, priority: 1_000_000.05.to_d),
          ]
        )
        expect(action_scheduler.cancel_out_of_boundaries_orders(:buy, price_levels[:bids].last&.price_point, proc { true })).to eq(
          [
            Arke::Action.new(:order_stop, target, order: order_buy_11, priority: 1_000_000.1.to_d),
            Arke::Action.new(:order_stop, target, order: order_buy_12, priority: 1_000_000.2.to_d),
          ]
        )
      end
    end
  end

  it "does nothing when all orders are in bounds" do
    expect(action_scheduler.cancel_risky_orders(:sell, 1.8)).to eq([])
    expect(action_scheduler.cancel_risky_orders(:buy, 1.5)).to eq([])
  end

  context "high_liquidity_sell_flag" do
    let(:opts) do
      {
        price_levels:    price_levels,
        limit_asks_base: 10
      }
    end

    it "raises the flag when current sell side liquidity go over the limits" do
      current_openorders.add_order(Arke::Order.new(market, 1.9, 1, :sell, "limit", 13))
      current_openorders.add_order(Arke::Order.new(market, 2.0, 1, :sell, "limit", 14))
      current_openorders.add_order(Arke::Order.new(market, 2.0, 9, :sell, "limit", 15))
      expect(action_scheduler.high_liquidity_sell_flag).to be(false)
    end

    it "raises the flag when current sell side liquidity go over the limits" do
      current_openorders.add_order(Arke::Order.new(market, 1.9, 1, :sell, "limit", 13))
      current_openorders.add_order(Arke::Order.new(market, 2.0, 1, :sell, "limit", 14))
      current_openorders.add_order(Arke::Order.new(market, 2.0, 9, :sell, "limit", 15))
      current_openorders.add_order(Arke::Order.new(market, 1.9, 3, :sell, "limit", 16))
      expect(action_scheduler.high_liquidity_sell_flag).to be(true)
    end
  end

  context "high_liquidity_buy_flag with limit_bids_base option" do
    let(:opts) do
      {
        price_levels:    price_levels,
        limit_bids_base: 10
      }
    end

    it "raises the flag when current buy side liquidity go over the limits" do
      current_openorders.add_order(Arke::Order.new(market, 1.9, 1, :buy, "limit", 13))
      current_openorders.add_order(Arke::Order.new(market, 2.0, 1, :buy, "limit", 14))
      current_openorders.add_order(Arke::Order.new(market, 2.0, 9, :buy, "limit", 15))
      expect(action_scheduler.high_liquidity_buy_flag).to be(false)
    end
    it "raises the flag when current buy side liquidity go over the limits" do
      current_openorders.add_order(Arke::Order.new(market, 1.9, 1, :buy, "limit", 13))
      current_openorders.add_order(Arke::Order.new(market, 2.0, 1, :buy, "limit", 14))
      current_openorders.add_order(Arke::Order.new(market, 2.0, 9, :buy, "limit", 15))
      current_openorders.add_order(Arke::Order.new(market, 1.9, 3, :buy, "limit", 16))
      expect(action_scheduler.high_liquidity_buy_flag).to be(true)
    end
  end

  context "high_liquidity_buy_flag with limit_bids_quote option" do
    let(:opts) do
      {
        price_levels:     price_levels,
        limit_bids_quote: 100
      }
    end

    it "does not raises the flag when current buy side liquidity is lower the limit" do
      current_openorders.add_order(Arke::Order.new(market, 10, 1, :buy, "limit", 13))
      current_openorders.add_order(Arke::Order.new(market, 10, 1, :buy, "limit", 14))
      current_openorders.add_order(Arke::Order.new(market, 10, 9, :buy, "limit", 15))
      expect(action_scheduler.high_liquidity_buy_flag).to be(false)
    end

    it "raises the flag when current buy side liquidity go over the limits" do
      current_openorders.add_order(Arke::Order.new(market, 10, 1, :buy, "limit", 13))
      current_openorders.add_order(Arke::Order.new(market, 10, 1, :buy, "limit", 14))
      current_openorders.add_order(Arke::Order.new(market, 10, 9, :buy, "limit", 15))
      current_openorders.add_order(Arke::Order.new(market, 10, 2, :buy, "limit", 16))
      expect(action_scheduler.high_liquidity_buy_flag).to be(true)
    end
  end

  context "cancel_risky_orders" do
    let(:order_sell_14) { Arke::Order.new(market, 2.0, 1, :sell, "limit", 14) }
    let(:order_sell_13) { Arke::Order.new(market, 1.9, 1, :sell, "limit", 13) }
    let(:order_buy_10)  { Arke::Order.new(market, 1.4, 3, :buy,  "limit", 10) }
    let(:order_buy_11)  { Arke::Order.new(market, 1.0, 1, :buy,  "limit", 11) }
    let(:order_buy_12)  { Arke::Order.new(market, 0.9, 1, :buy,  "limit", 12) }

    before(:each) do
      current_openorders.add_order(order_buy_10)
      current_openorders.add_order(order_buy_11)
      current_openorders.add_order(order_buy_12)
      current_openorders.add_order(order_sell_13)
      current_openorders.add_order(order_sell_14)
    end

    it "cancels orders over the bounds with very high priority" do
      expect(action_scheduler.cancel_risky_orders(:sell, 2.0)).to eq(
        [
          Arke::Action.new(:order_stop, target, id: 13, order: order_sell_13, priority: 1_000_000_000.1),
        ]
      )

      expect(action_scheduler.cancel_risky_orders(:buy, 0.9)).to eq(
        [
          Arke::Action.new(:order_stop, target, id: 10, order: order_buy_10, priority: 1_000_000_000.5),
          Arke::Action.new(:order_stop, target, id: 11, order: order_buy_11, priority: 1_000_000_000.1),
        ]
      )
    end

    it "does nothing when all orders are in bounds" do
      expect(action_scheduler.cancel_risky_orders(:sell, 1.8)).to eq([])
      expect(action_scheduler.cancel_risky_orders(:buy, 1.5)).to eq([])
    end
  end

  context "adjust_levels" do
    let(:order_sell_14) { Arke::Order.new(market, 20, 1, :sell, "limit", 14) }
    let(:order_sell_13) { Arke::Order.new(market, 19, 1, :sell, "limit", 13) }
    let(:order_sell_15) { Arke::Order.new(market, 18, 1, :sell, "limit", 15) }

    let(:order_buy_10)  { Arke::Order.new(market, 14, 3, :buy,  "limit", 10) }
    let(:order_buy_11)  { Arke::Order.new(market, 10, 1, :buy,  "limit", 11) }
    let(:order_buy_12)  { Arke::Order.new(market, 9, 1, :buy, "limit", 12) }
    let(:opts) do
      {
        price_levels:         price_levels,
        max_amount_per_order: 0.5,
      }
    end

    before(:each) do
      current_openorders.add_order(order_buy_10)
      current_openorders.add_order(order_buy_11)
      current_openorders.add_order(order_buy_12)
      current_openorders.add_order(order_sell_13)
      current_openorders.add_order(order_sell_14)

      desired_orderbook.update(Arke::Order.new(market, 22, 1.2, :sell))
      desired_orderbook.update(Arke::Order.new(market, 20, 1.1, :sell))

      desired_orderbook.update(Arke::Order.new(market, 21, 1, :buy))
      desired_orderbook.update(Arke::Order.new(market, 19, 1, :buy))
    end

    it "creates orders when levels need liquidity" do
      price_points = [
        ::Arke::PricePoint.new(20, 19.5),
        ::Arke::PricePoint.new(24, 22.5),
      ]
      expect(action_scheduler.adjust_levels(:sell, price_points, 20, proc { false }, proc { false })).to eq(
        [
          ::Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 22.5, 0.5, :sell), priority: 1028.571429),
          ::Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 22.5, 0.5, :sell), priority: 1028.571429),
          ::Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 22.5, 0.2, :sell), priority: 1028.571429),
        ]
      )
    end
  end
end
