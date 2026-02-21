# frozen_string_literal: true

module DeltaCore
  module Adapters
    class ActiveRecord
      include Base

      def initialize(config)
        @config = config
      end

      def load_snapshot(model)
        raw = model.public_send(@config.snapshot_column)
        Snapshot.new(raw)
      end

      def persist(model, serialized_json)
        model.update_column(@config.snapshot_column, serialized_json)
      end

      def lock_record(model, &)
        model.with_lock(&)
      end
    end
  end
end
