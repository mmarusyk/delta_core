# frozen_string_literal: true

RSpec.describe DeltaCore do
  it "has a version number" do
    expect(DeltaCore::VERSION).not_to be_nil
  end

  it "has version 1.0.0" do
    expect(DeltaCore::VERSION).to eq("1.0.0")
  end

  describe "Error" do
    it "is a subclass of StandardError" do
      expect(described_class::Error.superclass).to eq(StandardError)
    end
  end

  describe "EmptyDeltaError" do
    it "is a subclass of DeltaCore::Error" do
      expect(described_class::EmptyDeltaError.superclass).to eq(DeltaCore::Error)
    end
  end

  describe ".strategy_registry" do
    it "returns a Hash" do
      expect(described_class.strategy_registry).to be_a(Hash)
    end
  end

  describe ".register_strategy" do
    after { described_class.strategy_registry.delete(:test_strat) }

    it "stores the strategy class under the given name" do
      klass = Module.new
      described_class.register_strategy(:test_strat, klass)
      expect(described_class.strategy_registry[:test_strat]).to eq(klass)
    end

    it "coerces string name to symbol" do
      klass = Module.new
      described_class.register_strategy("test_strat", klass)
      expect(described_class.strategy_registry[:test_strat]).to eq(klass)
    end

    it "overwrites on duplicate registration" do
      klass1 = Module.new
      klass2 = Module.new
      described_class.register_strategy(:test_strat, klass1)
      described_class.register_strategy(:test_strat, klass2)
      expect(described_class.strategy_registry[:test_strat]).to eq(klass2)
    end
  end

  describe ".register_mapping_extension" do
    let(:ext) { ->(e, _r, _m) { e } }

    after { DeltaCore::StateBuilder.extensions.delete(ext) }

    it "adds the callable to StateBuilder.extensions" do
      described_class.register_mapping_extension(ext)
      expect(DeltaCore::StateBuilder.extensions).to include(ext)
    end
  end

  describe "DSL configuration" do
    it "allows configuring a snapshot column" do
      config = DeltaCore::Configuration.new
      config.snapshot_column(:delta_data)
      expect(config.snapshot_column).to eq(:delta_data)
    end

    it "allows mapping associations with key, fields, and strategy" do
      config = DeltaCore::Configuration.new
      config.map(:items, key: :product_id, fields: [:quantity], strategy: :quantity)
      expect(config.mappings.first.name).to eq(:items)
    end

    it "supports nested relation mapping" do
      config = DeltaCore::Configuration.new
      config.map(:items, key: :id, fields: [], strategy: :merge,
                         relations: { prices: { key: :id, fields: [:amount], strategy: :replace } })
      expect(config.mappings.first.relations[:prices]).to be_a(DeltaCore::Mapping)
    end
  end

  describe "snapshot capture" do
    it "persists snapshot data only after external confirmation" do
      config = DeltaCore::Configuration.new
      config.snapshot_column(:delta_col)
      adapter = instance_double(DeltaCore::Adapters::ActiveRecord)
      context = DeltaCore::Context.new(config, adapter: adapter)
      model   = double("model")

      allow(adapter).to receive(:load_snapshot).and_return(DeltaCore::Snapshot.new(nil))
      allow(config).to receive(:mappings).and_return([])

      expect(adapter).not_to receive(:persist)
      context.calculate_delta(model)
    end
  end

  describe "delta computation" do
    let(:config) do
      cfg = DeltaCore::Configuration.new
      cfg.snapshot_column(:delta_col)
      cfg.map(:items, key: :id, fields: [:qty], strategy: :quantity)
      cfg
    end

    let(:adapter) { instance_double(DeltaCore::Adapters::ActiveRecord) }
    let(:model)   { double("model", items: []) }
    let(:context) { DeltaCore::Context.new(config, adapter: adapter) }

    before do
      allow(adapter).to receive(:load_snapshot).and_return(DeltaCore::Snapshot.new(nil))
    end

    it "returns added entities present in current state but absent from snapshot" do
      item = double("item", id: 1, qty: 5)
      allow(model).to receive(:items).and_return([item])
      result = context.calculate_delta(model)
      expect(result.added.length).to eq(1)
    end

    it "returns removed entities present in snapshot but absent from current state" do
      snap_json = DeltaCore::Snapshot.new.serialize({ items: [{ id: 1, qty: 5 }] })
      allow(adapter).to receive(:load_snapshot).and_return(DeltaCore::Snapshot.new(snap_json))
      result = context.calculate_delta(model)
      expect(result.removed.length).to eq(1)
    end

    it "returns modified entities with changed field values" do
      snap_json = DeltaCore::Snapshot.new.serialize({ items: [{ id: 1, qty: 5 }] })
      allow(adapter).to receive(:load_snapshot).and_return(DeltaCore::Snapshot.new(snap_json))
      item = double("item", id: 1, qty: 10)
      allow(model).to receive(:items).and_return([item])
      result = context.calculate_delta(model)
      expect(result.modified.length).to eq(1)
    end

    it "reports empty? when no differences exist" do
      snap_json = DeltaCore::Snapshot.new.serialize({ items: [{ id: 1, qty: 5 }] })
      allow(adapter).to receive(:load_snapshot).and_return(DeltaCore::Snapshot.new(snap_json))
      item = double("item", id: 1, qty: 5)
      allow(model).to receive(:items).and_return([item])
      result = context.calculate_delta(model)
      expect(result).to be_empty
    end
  end
end
