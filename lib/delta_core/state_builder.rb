# frozen_string_literal: true

module DeltaCore
  class StateBuilder
    @extensions = []

    class << self
      attr_reader :extensions

      def build(model, config)
        new(model, config).build
      end
    end

    def initialize(model, config)
      @model  = model
      @config = config
    end

    def build
      @config.mappings.each_with_object({}) do |mapping, state|
        state[mapping.name] = build_collection(mapping)
      end
    end

    private

    def build_collection(mapping)
      collection = @model.public_send(mapping.name)
      Array(collection)
        .map { |record| build_record(record, mapping) }
        .sort_by { |h| h[mapping.key].to_s }
    end

    def build_record(record, mapping)
      entity = { mapping.key => extract_value(record, mapping.key) }

      mapping.fields.each do |field|
        entity[field] = extract_value(record, field)
      end

      mapping.relations.each do |assoc_name, rel_mapping|
        entity[assoc_name] = build_nested(record, rel_mapping)
      end

      apply_extensions(entity, record, mapping)
    end

    def build_nested(record, rel_mapping)
      collection = record.public_send(rel_mapping.name)
      Array(collection)
        .map { |r| build_record(r, rel_mapping) }
        .sort_by { |h| h[rel_mapping.key].to_s }
    end

    def extract_value(record, field)
      record.public_send(field)
    end

    def apply_extensions(entity, record, mapping)
      self.class.extensions.reduce(entity) do |e, ext|
        ext.respond_to?(:call) ? ext.call(e, record, mapping) : e
      end
    end
  end
end
