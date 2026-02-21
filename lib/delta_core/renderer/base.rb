# frozen_string_literal: true

module DeltaCore
  module Renderer
    module Base
      def call(_delta_result)
        raise NotImplementedError, "#{self.class}#call not implemented"
      end
    end
  end
end
