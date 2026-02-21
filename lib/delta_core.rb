# frozen_string_literal: true

require "json"

require_relative "delta_core/version"
require_relative "delta_core/mapping"
require_relative "delta_core/configuration"
require_relative "delta_core/delta_result"
require_relative "delta_core/snapshot"
require_relative "delta_core/state_builder"
require_relative "delta_core/strategies/base"
require_relative "delta_core/strategies/quantity"
require_relative "delta_core/strategies/replace"
require_relative "delta_core/strategies/merge"
require_relative "delta_core/comparator"
require_relative "delta_core/adapters/base"
require_relative "delta_core/adapters/active_record"
require_relative "delta_core/context"
require_relative "delta_core/renderer/base"
require_relative "delta_core/dsl"

module DeltaCore
  class Error < StandardError; end
  class EmptyDeltaError < Error; end

  @strategy_registry = {}

  class << self
    attr_reader :strategy_registry

    def register_strategy(name, klass)
      @strategy_registry[name.to_sym] = klass
    end

    def register_mapping_extension(callable)
      StateBuilder.extensions << callable
    end
  end
end
