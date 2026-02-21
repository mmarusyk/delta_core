# frozen_string_literal: true

module DeltaCore
  module Adapters
    module Base
      def load_snapshot(_model)
        raise NotImplementedError, "#{self.class}#load_snapshot not implemented"
      end

      def persist(_model, _serialized_json)
        raise NotImplementedError, "#{self.class}#persist not implemented"
      end

      def lock_record(_model)
        raise NotImplementedError, "#{self.class}#lock_record not implemented"
      end
    end
  end
end
