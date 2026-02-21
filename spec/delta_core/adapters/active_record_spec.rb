# frozen_string_literal: true

RSpec.describe DeltaCore::Adapters::ActiveRecord do
  subject(:adapter) { described_class.new(config) }

  let(:config) do
    cfg = DeltaCore::Configuration.new
    cfg.snapshot_column(:delta_data)
    cfg
  end
  let(:model) do
    double("ar_model",
           delta_data: nil,
           update_column: true)
  end

  describe "#load_snapshot" do
    it "returns a Snapshot instance" do
      expect(adapter.load_snapshot(model)).to be_a(DeltaCore::Snapshot)
    end

    it "reads from the configured column" do
      expect(model).to receive(:public_send).with(:delta_data).and_return(nil)
      adapter.load_snapshot(model)
    end

    it "returns empty Snapshot when column is nil" do
      snapshot = adapter.load_snapshot(model)
      expect(snapshot).to be_empty
    end

    it "returns populated Snapshot when column has JSON" do
      json = DeltaCore::Snapshot.new.serialize({ items: [{ id: 1 }] })
      allow(model).to receive(:public_send).with(:delta_data).and_return(json)
      snapshot = adapter.load_snapshot(model)
      expect(snapshot).not_to be_empty
    end
  end

  describe "#persist" do
    it "calls update_column with the column name and JSON" do
      json = '{"_v":1}'
      expect(model).to receive(:update_column).with(:delta_data, json)
      adapter.persist(model, json)
    end
  end

  describe "#lock_record" do
    it "calls with_lock on the model and yields" do
      yielded = false
      allow(model).to receive(:with_lock).and_yield
      adapter.lock_record(model) { yielded = true }
      expect(yielded).to be(true)
    end

    it "passes the block to with_lock" do
      expect(model).to receive(:with_lock)
      adapter.lock_record(model) { nil }
    end
  end
end
