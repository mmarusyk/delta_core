# frozen_string_literal: true

module DeltaCore
  module Strategies
    module Base
      def self.call(_snapshot_collection, _current_collection, _mapping)
        raise NotImplementedError, "#{name} must implement .call"
      end

      def self.index_by_key(collection, key)
        collection.each_with_object({}) do |entity, idx|
          idx[entity[key]] = entity
        end
      end
    end
  end
end
