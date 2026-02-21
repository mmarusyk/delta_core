# frozen_string_literal: true

module DeltaCore
  class Configuration
    attr_reader :mappings

    def initialize
      @snapshot_column = nil
      @mappings        = []
    end

    def snapshot_column(column_name = nil)
      if column_name
        @snapshot_column = column_name.to_sym
      else
        @snapshot_column
      end
    end

    def map(name, key:, strategy:, fields: [], relations: {})
      sym = name.to_sym
      raise ArgumentError, "Duplicate mapping: #{sym}" if mapping_names.include?(sym)

      mapping = Mapping.new(sym, key: key, fields: fields, strategy: strategy, relations: relations)
      @mappings << mapping
      mapping
    end

    private

    def mapping_names
      @mappings.map(&:name)
    end
  end
end
