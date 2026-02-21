# frozen_string_literal: true

RSpec.describe DeltaCore::Context do
  let(:config) do
    cfg = DeltaCore::Configuration.new
    cfg.snapshot_column(:delta_col)
    cfg.map(:items, key: :id, fields: [:qty], strategy: :quantity)
    cfg
  end

  let(:adapter)    { instance_double(DeltaCore::Adapters::ActiveRecord) }
  let(:context)    { described_class.new(config, adapter: adapter) }
  let(:model)      { double("model", items: []) }
  let(:empty_snap) { DeltaCore::Snapshot.new(nil) }

  before { allow(adapter).to receive(:load_snapshot).and_return(empty_snap) }

  describe "#build_state" do
    it "returns a hash" do
      expect(context.build_state(model)).to be_a(Hash)
    end

    it "delegates to StateBuilder" do
      expect(DeltaCore::StateBuilder).to receive(:build).with(model, config).and_call_original
      context.build_state(model)
    end
  end

  describe "#calculate_delta" do
    it "returns a DeltaResult" do
      expect(context.calculate_delta(model)).to be_a(DeltaCore::DeltaResult)
    end

    it "never calls persist" do
      expect(adapter).not_to receive(:persist)
      context.calculate_delta(model)
    end

    context "when there are no changes" do
      it "returns empty result" do
        expect(context.calculate_delta(model)).to be_empty
      end
    end

    context "when current has new items" do
      it "returns a non-empty result" do
        item = double("item", id: 1, qty: 5)
        allow(model).to receive(:items).and_return([item])
        expect(context.calculate_delta(model)).not_to be_empty
      end
    end
  end

  describe "#update_snapshot" do
    context "when delta is empty" do
      it "raises EmptyDeltaError" do
        expect do
          context.update_snapshot(model)
        end.to raise_error(DeltaCore::EmptyDeltaError, /empty/)
      end
    end

    context "when delta is non-empty" do
      let(:item) { double("item", id: 1, qty: 5) }

      before do
        allow(model).to receive(:items).and_return([item])
        allow(adapter).to receive(:lock_record).and_yield
        allow(adapter).to receive(:persist)
      end

      it "calls lock_record on the adapter" do
        expect(adapter).to receive(:lock_record).and_yield
        context.update_snapshot(model)
      end

      it "calls persist with serialized JSON" do
        expect(adapter).to receive(:persist).with(model, instance_of(String))
        context.update_snapshot(model)
      end

      it "does not raise" do
        expect { context.update_snapshot(model) }.not_to raise_error
      end
    end
  end

  describe "#with_delta_transaction" do
    context "without a block" do
      it "raises ArgumentError" do
        expect { context.with_delta_transaction(model) }.to raise_error(ArgumentError, /Block required/)
      end
    end

    context "when delta is empty" do
      it "raises EmptyDeltaError" do
        allow(adapter).to receive(:lock_record).and_yield
        expect do
          context.with_delta_transaction(model) { |_delta| nil }
        end.to raise_error(DeltaCore::EmptyDeltaError)
      end
    end

    context "when delta is non-empty" do
      let(:item) { double("item", id: 1, qty: 5) }

      before do
        allow(model).to receive(:items).and_return([item])
        allow(adapter).to receive(:lock_record).and_yield
        allow(adapter).to receive(:persist)
      end

      it "yields the DeltaResult to the block" do
        yielded = nil
        context.with_delta_transaction(model) { |delta| yielded = delta }
        expect(yielded).to be_a(DeltaCore::DeltaResult)
      end

      it "returns the block's return value" do
        result = context.with_delta_transaction(model) { |_| 42 }
        expect(result).to eq(42)
      end

      it "persists the snapshot after a successful block" do
        expect(adapter).to receive(:persist)
        context.with_delta_transaction(model) { |_| nil }
      end

      context "when the block raises" do
        it "does not persist the snapshot" do
          expect(adapter).not_to receive(:persist)
          expect do
            context.with_delta_transaction(model) { raise "transmission failed" }
          end.to raise_error(RuntimeError, "transmission failed")
        end
      end
    end
  end

  describe "#reset_flags" do
    it "is a no-op — does not raise" do
      expect { context.reset_flags(model) }.not_to raise_error
    end

    it "returns nil" do
      expect(context.reset_flags(model)).to be_nil
    end
  end
end
