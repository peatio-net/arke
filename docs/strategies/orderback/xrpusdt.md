```yml
log_level: INFO                       # Level of Arke log info

accounts:
#---------------------------{source}-----------------------------------
- id: binance_source                  # Unique account id of the source
  driver: binance                     # One of supported sources drivers
  delay: 1                            # Delay of balance information update
  key: ""                             # API key from source (not required for copy strategy)
  secret: ""                          # Secret from API key from source (not required for copy strategy)

#---------------------------{target}-----------------------------------
- id: rubykube_target                 # Unique account id of the target
  driver: rubykube                    # Only supported target driver
  key: ""                             # API key from the target, required
  secret: ""                          # Secret from API key from the target, required
  host: "https://demo.openware.work"  # Your target URL
  ws: "wss://demo.openware.work"      # Your target WebSocet URL

strategies:
#---------------------------{strategy}-----------------------------------
- id: orderback-XRPUSD                # Name of a strategy
  type: orderback                     # Type of the strategy
  debug: false                        # True to see extra Arke logs
  enabled: true                       # True to run this strategy after Arke (re)startgit
  period: 90                          # Period of order book refresh
  params:
    spread_bids: 0.02                 # Percentage difference from the best price on buy side
    spread_asks: 0.02                 # Percentage difference from the best price on sell side
    limit_asks_quote: 10000           # The amount of quote currency that will be placed for sale in the order book
    limit_bids_quote: 9500            # The amount of quote currency that will be placed for buy in the order book
    # balance_base_perc: 0.5          # Ratio for sum of amounts of orders of ask side based on base currency balance
    # balance_quote_perc: 0.5         # Ratio for sum of amounts of orders of bid side based on quote currency balance
    max_amount_per_order: 500         # Limit amount of base currency per order (the small amount are, the bigger number of orders at the same price will be created)
    levels_size: 0.00001              # Minimum price difference between price points
    levels_count: 10                  # Maximum amount of price points that may be created
    side: both                        # Side, ask, bid or both to apply the strategy on
    apply_safe_limits_on_source: true # Applies the same limits (percentage or static value) to the source balances. This helps to make sure all orders can be filled from the source in case of many trades would happen at the same time on the target.
    enable_orderback: true            # True to perform order back on the source, if on target exchange orders was matched with this strategy
    min_order_back_amount: 5          # The minimum amount of tokens bought or sold on target exchange at the same price point in a period of a second to perform an order back (made to ignore microtrade strategy)
  target:
    account_id: rubykube_target       # Unique account id, from the account section, that will be used as a target (your exchange)
    market_id: xrpusd                 # Market pair code in lowercase, from your target exchange
  sources:
  - account_id: binance_source        # Unique account id, from the account section, that will be used as a source
    market_id: XRPUSDT                # Market pair code in uppercase, from you source exchange
