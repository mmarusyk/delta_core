# frozen_string_literal: true

RSpec.describe DeltaCore::Mapping do
  subject(:mapping) do
    described_class.new(:items, key: :product_id, fields: %i[quantity unit_price], strategy: :quantity)
  end

  describe "#name" do
    it "returns the association name as a symbol" do
      expect(mapping.name).to eq(:items)
    end

    it "coerces string name to symbol" do
      m = described_class.new("items", key: :id, fields: [], strategy: :merge)
      expect(m.name).to eq(:items)
    end
  end

  describe "#key" do
    it "returns the key field as a symbol" do
      expect(mapping.key).to eq(:product_id)
    end
  end

  describe "#fields" do
    it "returns fields as an array of symbols" do
      expect(mapping.fields).to eq(%i[quantity unit_price])
    end

    it "returns empty array when no fields given" do
      m = described_class.new(:items, key: :id, fields: [], strategy: :merge)
      expect(m.fields).to eq([])
    end

    it "wraps a single symbol field in an array" do
      m = described_class.new(:items, key: :id, fields: :qty, strategy: :quantity)
      expect(m.fields).to eq([:qty])
    end

    it "handles nil fields gracefully" do
      m = described_class.new(:items, key: :id, fields: nil, strategy: :quantity)
      expect(m.fields).to eq([])
    end
  end

  describe "#strategy" do
    it "returns the strategy as a symbol" do
      expect(mapping.strategy).to eq(:quantity)
    end
  end

  describe "#relations" do
    it "returns empty hash when no relations given" do
      expect(mapping.relations).to eq({})
    end

    it "builds nested Mapping objects from relations hash" do
      m = described_class.new(
        :items,
        key: :product_id,
        fields: [:qty],
        strategy: :quantity,
        relations: {
          price_changes: { key: :id, fields: %i[amount type], strategy: :replace }
        }
      )
      expect(m.relations[:price_changes]).to be_a(described_class)
    end

    it "sets the nested mapping key correctly" do
      m = described_class.new(
        :items,
        key: :product_id,
        fields: [],
        strategy: :quantity,
        relations: {
          prices: { key: :price_id, fields: [:amount], strategy: :merge }
        }
      )
      expect(m.relations[:prices].key).to eq(:price_id)
    end

    it "sets the nested mapping strategy correctly" do
      m = described_class.new(
        :items,
        key: :id,
        fields: [],
        strategy: :quantity,
        relations: {
          charges: { key: :id, fields: [:amount], strategy: :replace }
        }
      )
      expect(m.relations[:charges].strategy).to eq(:replace)
    end

    it "handles nil relations gracefully" do
      m = described_class.new(:items, key: :id, fields: [], strategy: :quantity, relations: nil)
      expect(m.relations).to eq({})
    end

    it "coerces relation keys to symbols" do
      m = described_class.new(
        :items,
        key: :id,
        fields: [],
        strategy: :quantity,
        relations: {
          "charges" => { key: :id, fields: [], strategy: :replace }
        }
      )
      expect(m.relations.keys).to eq([:charges])
    end
  end

  describe "missing required arguments" do
    it "raises KeyError when key: is missing" do
      expect { described_class.new(:items, fields: [], strategy: :quantity) }.to raise_error(ArgumentError)
    end

    it "raises KeyError when strategy: is missing" do
      expect { described_class.new(:items, key: :id, fields: []) }.to raise_error(ArgumentError)
    end
  end
end
