# frozen_string_literal: true

module DeltaCore
  module Strategies
    module Replace
      def self.call(snapshot_collection, current_collection, _mapping)
        return { added: [], removed: [], modified: [] } if snapshot_collection == current_collection

        { added: current_collection, removed: snapshot_collection, modified: [] }
      end
    end
  end
end
