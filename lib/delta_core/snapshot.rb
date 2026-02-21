# frozen_string_literal: true

module DeltaCore
  class Snapshot
    FORMAT_VERSION = 1
    VERSION_KEY    = "_v"

    attr_reader :state

    def initialize(raw = nil)
      @state = parse(raw)
    end

    def empty?
      @state.empty?
    end

    def serialize(current_state)
      payload = { VERSION_KEY => FORMAT_VERSION }
      payload.merge!(stringify_keys(current_state))
      JSON.generate(payload)
    end

    private

    def parse(raw)
      return {} if raw.nil? || raw.to_s.strip.empty?

      parsed = JSON.parse(raw.to_s, symbolize_names: true)
      return {} unless parsed.is_a?(Hash)

      parsed.except(:_v)
    rescue JSON::ParserError
      {}
    end

    def stringify_keys(hash)
      hash.transform_keys(&:to_s)
    end
  end
end
