# frozen_string_literal: true

module DeltaCore
  module DSL
    module ClassMethods
      def delta_core(&)
        config = Configuration.new
        config.instance_eval(&)
        @delta_core_config = config

        include InstanceMethods
      end

      def delta_core_config
        @delta_core_config
      end
    end

    module InstanceMethods
      def delta_state
        DeltaCore::Context.new(self.class.delta_core_config).build_state(self)
      end

      def delta_result
        DeltaCore::Context.new(self.class.delta_core_config).calculate_delta(self)
      end

      def confirm_snapshot!
        DeltaCore::Context.new(self.class.delta_core_config).update_snapshot(self)
      end

      def reset_delta_flags!
        DeltaCore::Context.new(self.class.delta_core_config).reset_flags(self)
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end

  Model = DSL

  ::ActiveRecord::Base.include(DSL) if defined?(::ActiveRecord::Base)
end
