# frozen_string_literal: true

require "clamp"

require "arke/core"

require "arke/strategy/base"
require "arke/strategy/copy"
require "arke/strategy/fixedprice"
require "arke/strategy/microtrades_copy"
require "arke/strategy/microtrades_market"
require "arke/strategy/microtrades"
require "arke/strategy/orderback"
require "arke/strategy/circuitbraker"
require "arke/strategy/candle_sampling"
require "arke/strategy/simple_copy"

require "arke/command"
require "arke/command/order"
require "arke/command/show"
require "arke/command/start"
require "arke/command/version"
require "arke/command/root"
