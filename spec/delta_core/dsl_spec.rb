# frozen_string_literal: true

RSpec.describe DeltaCore::DSL do
  # Minimal host class that includes the DSL
  let(:host_class) do
    Class.new do
      include DeltaCore::DSL

      delta_core do
        snapshot_column :delta_data
        map :items, key: :id, fields: [:name], strategy: :merge
      end

      def items
        []
      end
    end
  end

  let(:instance) { host_class.new }
  let(:adapter)  { instance_double(DeltaCore::Adapters::ActiveRecord) }

  before { allow(adapter).to receive(:load_snapshot).and_return(DeltaCore::Snapshot.new(nil)) }

  describe ".delta_core_config" do
    it "returns a Configuration" do
      expect(host_class.delta_core_config).to be_a(DeltaCore::Configuration)
    end

    it "stores the configured snapshot column" do
      expect(host_class.delta_core_config.snapshot_column).to eq(:delta_data)
    end

    it "stores the configured mappings" do
      expect(host_class.delta_core_config.mappings.first.name).to eq(:items)
    end
  end

  describe "instance methods" do
    before do
      allow(DeltaCore::Adapters::ActiveRecord).to receive(:new).and_return(adapter)
      allow(adapter).to receive(:lock_record).and_yield
      allow(adapter).to receive(:persist)
    end

    describe "#delta_state" do
      it "returns a Hash" do
        expect(instance.delta_state).to be_a(Hash)
      end
    end

    describe "#delta_result" do
      it "returns a DeltaResult" do
        expect(instance.delta_result).to be_a(DeltaCore::DeltaResult)
      end
    end

    describe "#confirm_snapshot!" do
      it "raises EmptyDeltaError when there is nothing to snapshot" do
        expect { instance.confirm_snapshot! }.to raise_error(DeltaCore::EmptyDeltaError)
      end
    end

    describe "#reset_delta_flags!" do
      it "does not raise" do
        expect { instance.reset_delta_flags! }.not_to raise_error
      end
    end
  end

  describe "class isolation" do
    it "two different classes each get their own config" do
      class_a = Class.new do
        include DeltaCore::DSL

        delta_core { snapshot_column :col_a }
      end
      class_b = Class.new do
        include DeltaCore::DSL

        delta_core { snapshot_column :col_b }
      end
      expect(class_a.delta_core_config.snapshot_column).to eq(:col_a)
      expect(class_b.delta_core_config.snapshot_column).to eq(:col_b)
    end
  end

  describe "DeltaCore::Model alias" do
    it "is the same module as DeltaCore::DSL" do
      expect(DeltaCore::Model).to eq(described_class)
    end
  end

  describe "DSL block errors" do
    it "raises ArgumentError on duplicate map name in DSL block" do
      expect do
        Class.new do
          include DeltaCore::DSL

          delta_core do
            map :items, key: :id, fields: [], strategy: :quantity
            map :items, key: :id, fields: [], strategy: :replace
          end
        end
      end.to raise_error(ArgumentError, /items/)
    end
  end
end
