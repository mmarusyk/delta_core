# frozen_string_literal: true

module DeltaCore
  class Mapping
    attr_reader :name, :key, :fields, :strategy, :relations

    def initialize(name, key:, strategy:, fields: [], relations: {})
      @name      = name.to_sym
      @key       = key.to_sym
      @fields    = Array(fields).map(&:to_sym)
      @strategy  = strategy.to_sym
      @relations = build_relations(relations || {})
    end

    private

    def build_relations(raw)
      raw.each_with_object({}) do |(assoc_name, opts), result|
        result[assoc_name.to_sym] = Mapping.new(
          assoc_name,
          key: opts.fetch(:key),
          fields: opts.fetch(:fields, []),
          strategy: opts.fetch(:strategy),
          relations: opts.fetch(:relations, {})
        )
      end
    end
  end
end
