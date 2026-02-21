# frozen_string_literal: true

module DeltaCore
  class Context
    def initialize(config, adapter: nil)
      @config  = config
      @adapter = adapter || Adapters::ActiveRecord.new(config)
    end

    def build_state(model)
      StateBuilder.build(model, @config)
    end

    def calculate_delta(model)
      snapshot      = @adapter.load_snapshot(model)
      current_state = build_state(model)
      Comparator.compare(snapshot.state, current_state, @config)
    end

    def update_snapshot(model)
      delta = calculate_delta(model)
      raise EmptyDeltaError, "Cannot update snapshot: delta is empty" if delta.empty?

      @adapter.lock_record(model) do
        current_state  = build_state(model)
        serialized     = Snapshot.new.serialize(current_state)
        @adapter.persist(model, serialized)
      end
    end

    def with_delta_transaction(model)
      raise ArgumentError, "Block required" unless block_given?

      result = nil

      @adapter.lock_record(model) do
        current_state = build_state(model)
        delta         = Comparator.compare(
          @adapter.load_snapshot(model).state,
          current_state,
          @config
        )

        raise EmptyDeltaError, "Delta is empty — nothing to transmit" if delta.empty?

        result = yield delta

        serialized = Snapshot.new.serialize(current_state)
        @adapter.persist(model, serialized)
      end

      result
    end

    def reset_flags(_model)
      # Extension point: clears any dirty-tracking metadata.
      # Default implementation is a no-op.
    end
  end
end
