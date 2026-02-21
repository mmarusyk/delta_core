# frozen_string_literal: true

RSpec.describe DeltaCore::Configuration do
  subject(:config) { described_class.new }

  describe "#snapshot_column" do
    it "returns nil by default" do
      expect(config.snapshot_column).to be_nil
    end

    it "sets the column when called with an argument" do
      config.snapshot_column(:my_col)
      expect(config.snapshot_column).to eq(:my_col)
    end

    it "coerces string to symbol" do
      config.snapshot_column("my_col")
      expect(config.snapshot_column).to eq(:my_col)
    end

    it "overwrites previous value" do
      config.snapshot_column(:first)
      config.snapshot_column(:second)
      expect(config.snapshot_column).to eq(:second)
    end
  end

  describe "#mappings" do
    it "returns empty array by default" do
      expect(config.mappings).to eq([])
    end
  end

  describe "#map" do
    it "adds a Mapping to mappings" do
      config.map(:items, key: :id, fields: [:qty], strategy: :quantity)
      expect(config.mappings.length).to eq(1)
    end

    it "returns a Mapping instance" do
      result = config.map(:items, key: :id, fields: [:qty], strategy: :quantity)
      expect(result).to be_a(DeltaCore::Mapping)
    end

    it "sets the mapping name" do
      config.map(:items, key: :id, fields: [:qty], strategy: :quantity)
      expect(config.mappings.first.name).to eq(:items)
    end

    it "preserves insertion order for multiple mappings" do
      config.map(:items, key: :id, fields: [], strategy: :quantity)
      config.map(:charges, key: :id, fields: [], strategy: :replace)
      expect(config.mappings.map(&:name)).to eq(%i[items charges])
    end

    it "defaults fields to empty array" do
      config.map(:items, key: :id, strategy: :quantity)
      expect(config.mappings.first.fields).to eq([])
    end

    it "supports relations option" do
      config.map(:items, key: :id, fields: [], strategy: :merge,
                         relations: { prices: { key: :id, fields: [:amount], strategy: :replace } })
      expect(config.mappings.first.relations[:prices]).to be_a(DeltaCore::Mapping)
    end

    it "raises ArgumentError on duplicate mapping name" do
      config.map(:items, key: :id, fields: [], strategy: :quantity)
      expect do
        config.map(:items, key: :id, fields: [], strategy: :replace)
      end.to raise_error(ArgumentError, /items/)
    end

    it "error message includes the duplicate name" do
      config.map(:items, key: :id, fields: [], strategy: :quantity)
      expect do
        config.map(:items, key: :id, fields: [], strategy: :replace)
      end.to raise_error(ArgumentError, "Duplicate mapping: items")
    end
  end
end
