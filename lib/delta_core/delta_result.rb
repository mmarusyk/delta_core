# frozen_string_literal: true

module DeltaCore
  class DeltaResult
    attr_reader :added, :removed, :modified

    def initialize(added: [], removed: [], modified: [])
      @added    = Array(added).freeze
      @removed  = Array(removed).freeze
      @modified = Array(modified).freeze
      freeze
    end

    def empty?
      added.empty? && removed.empty? && modified.empty?
    end

    def merge(other)
      self.class.new(
        added: added + other.added,
        removed: removed + other.removed,
        modified: modified + other.modified
      )
    end

    def render(renderer)
      renderer.call(self)
    end
  end
end
