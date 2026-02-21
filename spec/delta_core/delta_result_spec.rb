# frozen_string_literal: true

RSpec.describe DeltaCore::DeltaResult do
  describe "#initialize" do
    it "creates an empty result with no arguments" do
      result = described_class.new
      expect(result.added).to eq([])
      expect(result.removed).to eq([])
      expect(result.modified).to eq([])
    end

    it "stores provided arrays" do
      result = described_class.new(added: [1], removed: [2], modified: [3])
      expect(result.added).to eq([1])
      expect(result.removed).to eq([2])
      expect(result.modified).to eq([3])
    end

    it "freezes the added array" do
      result = described_class.new(added: [1])
      expect(result.added).to be_frozen
    end

    it "freezes the removed array" do
      result = described_class.new(removed: [1])
      expect(result.removed).to be_frozen
    end

    it "freezes the modified array" do
      result = described_class.new(modified: [1])
      expect(result.modified).to be_frozen
    end

    it "freezes the result object itself" do
      result = described_class.new
      expect(result).to be_frozen
    end

    it "wraps nil added in empty array" do
      result = described_class.new(added: nil)
      expect(result.added).to eq([])
    end

    it "wraps nil removed in empty array" do
      result = described_class.new(removed: nil)
      expect(result.removed).to eq([])
    end

    it "wraps nil modified in empty array" do
      result = described_class.new(modified: nil)
      expect(result.modified).to eq([])
    end
  end

  describe "#empty?" do
    it "returns true when all arrays are empty" do
      expect(described_class.new).to be_empty
    end

    it "returns false when added is non-empty" do
      expect(described_class.new(added: [1])).not_to be_empty
    end

    it "returns false when removed is non-empty" do
      expect(described_class.new(removed: [1])).not_to be_empty
    end

    it "returns false when modified is non-empty" do
      expect(described_class.new(modified: [1])).not_to be_empty
    end
  end

  describe "#merge" do
    let(:a) { described_class.new(added: [1], removed: [2], modified: [3]) }
    let(:b) { described_class.new(added: [4], removed: [5], modified: [6]) }

    it "returns a new DeltaResult" do
      expect(a.merge(b)).to be_a(described_class)
      expect(a.merge(b)).not_to be(a)
    end

    it "concatenates added arrays" do
      expect(a.merge(b).added).to eq([1, 4])
    end

    it "concatenates removed arrays" do
      expect(a.merge(b).removed).to eq([2, 5])
    end

    it "concatenates modified arrays" do
      expect(a.merge(b).modified).to eq([3, 6])
    end

    it "does not mutate self" do
      a.merge(b)
      expect(a.added).to eq([1])
    end

    it "merging two empty results returns an empty result" do
      result = described_class.new.merge(described_class.new)
      expect(result).to be_empty
    end

    it "returns a frozen result" do
      expect(a.merge(b)).to be_frozen
    end
  end

  describe "#render" do
    it "calls the renderer with self and returns the result" do
      result   = described_class.new(added: [1])
      renderer = ->(delta) { delta.added.length }
      expect(result.render(renderer)).to eq(1)
    end

    it "works with any callable object" do
      result   = described_class.new(removed: [1, 2])
      renderer = ->(delta) { "removed: #{delta.removed.length}" }
      expect(result.render(renderer)).to eq("removed: 2")
    end
  end
end
