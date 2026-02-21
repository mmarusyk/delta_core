# frozen_string_literal: true

module DeltaCore
  module Strategies
    module Quantity
      def self.call(snapshot_collection, current_collection, mapping)
        snap_index = Base.index_by_key(snapshot_collection, mapping.key)
        curr_index = Base.index_by_key(current_collection, mapping.key)

        added   = curr_index.reject { |k, _| snap_index.key?(k) }.values
        removed = snap_index.reject { |k, _| curr_index.key?(k) }.values

        modified = curr_index.filter_map do |k, curr|
          snap = snap_index[k]
          next unless snap

          changed = mapping.fields.any? { |f| curr[f] != snap[f] }
          { current: curr, snapshot: snap } if changed
        end

        { added: added, removed: removed, modified: modified }
      end
    end
  end
end
