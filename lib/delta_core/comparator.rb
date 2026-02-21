# frozen_string_literal: true

module DeltaCore
  class Comparator
    BUILT_IN_STRATEGIES = {
      quantity: Strategies::Quantity,
      replace: Strategies::Replace,
      merge: Strategies::Merge
    }.freeze

    def self.compare(snapshot_state, current_state, config)
      new(snapshot_state, current_state, config).compare
    end

    def initialize(snapshot_state, current_state, config)
      @snapshot_state = snapshot_state
      @current_state  = current_state
      @config         = config
    end

    def compare
      @config.mappings.reduce(DeltaResult.new) do |result, mapping|
        snap_coll = Array(@snapshot_state[mapping.name])
        curr_coll = Array(@current_state[mapping.name])

        strategy = resolve_strategy(mapping.strategy)
        raw      = strategy.call(snap_coll, curr_coll, mapping)
        partial  = DeltaResult.new(**raw)
        nested   = compare_nested(snap_coll, curr_coll, mapping)

        result.merge(partial).merge(nested)
      end
    end

    private

    def resolve_strategy(name)
      BUILT_IN_STRATEGIES[name] ||
        DeltaCore.strategy_registry[name] ||
        raise(ArgumentError, "Unknown strategy: #{name.inspect}")
    end

    def compare_nested(snap_coll, curr_coll, mapping)
      return DeltaResult.new if mapping.relations.empty?

      snap_idx = Strategies::Base.index_by_key(snap_coll, mapping.key)
      curr_idx = Strategies::Base.index_by_key(curr_coll, mapping.key)

      mapping.relations.reduce(DeltaResult.new) do |rel_result, (rel_name, rel_mapping)|
        curr_idx.reduce(rel_result) do |inner_result, (_, curr_entity)|
          key_val     = curr_entity[mapping.key]
          snap_entity = snap_idx[key_val] || {}
          snap_nested = Array(snap_entity[rel_name])
          curr_nested = Array(curr_entity[rel_name])

          nested_snap = { rel_mapping.name => snap_nested }
          nested_curr = { rel_mapping.name => curr_nested }
          nested_cfg  = build_nested_config(rel_mapping)

          partial = self.class.compare(nested_snap, nested_curr, nested_cfg)
          inner_result.merge(partial)
        end
      end
    end

    def build_nested_config(rel_mapping)
      cfg = Configuration.new
      cfg.instance_variable_set(:@mappings, [rel_mapping])
      cfg
    end
  end
end
