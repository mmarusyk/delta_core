# frozen_string_literal: true

RSpec.describe DeltaCore::Comparator do
  let(:mapping) do
    DeltaCore::Mapping.new(:items, key: :id, fields: [:qty], strategy: :quantity)
  end

  let(:config) do
    cfg = DeltaCore::Configuration.new
    cfg.instance_variable_set(:@mappings, [mapping])
    cfg
  end

  describe ".compare" do
    it "returns a DeltaResult" do
      result = described_class.compare({}, {}, config)
      expect(result).to be_a(DeltaCore::DeltaResult)
    end

    context "when states are identical" do
      it "returns empty result" do
        state  = { items: [{ id: 1, qty: 5 }] }
        result = described_class.compare(state, state, config)
        expect(result).to be_empty
      end
    end

    context "when current has items not in snapshot" do
      it "returns added items" do
        snap   = {}
        curr   = { items: [{ id: 1, qty: 5 }] }
        result = described_class.compare(snap, curr, config)
        expect(result.added.length).to eq(1)
      end
    end

    context "when snapshot has items not in current" do
      it "returns removed items" do
        snap   = { items: [{ id: 1, qty: 5 }] }
        curr   = {}
        result = described_class.compare(snap, curr, config)
        expect(result.removed.length).to eq(1)
      end
    end

    context "when field values differ" do
      it "returns modified items" do
        snap   = { items: [{ id: 1, qty: 5 }] }
        curr   = { items: [{ id: 1, qty: 10 }] }
        result = described_class.compare(snap, curr, config)
        expect(result.modified.length).to eq(1)
      end
    end

    context "with multiple mappings" do
      it "merges results from all mappings" do
        cfg = DeltaCore::Configuration.new
        cfg.instance_variable_set(:@mappings, [
                                    DeltaCore::Mapping.new(:items, key: :id, fields: [:qty], strategy: :quantity),
                                    DeltaCore::Mapping.new(:charges, key: :id, fields: [:amount], strategy: :replace)
                                  ])
        snap   = { items: [{ id: 1, qty: 5 }], charges: [{ id: 1, amount: 10 }] }
        curr   = { items: [{ id: 2, qty: 3 }], charges: [{ id: 1, amount: 99 }] }
        result = described_class.compare(snap, curr, cfg)
        expect(result.added.length + result.removed.length).to be > 0
      end
    end

    context "with an unknown strategy" do
      it "raises ArgumentError" do
        bad_mapping = DeltaCore::Mapping.new(:items, key: :id, fields: [], strategy: :unknown_xyz)
        bad_config  = DeltaCore::Configuration.new
        bad_config.instance_variable_set(:@mappings, [bad_mapping])
        expect do
          described_class.compare({}, {}, bad_config)
        end.to raise_error(ArgumentError, /unknown_xyz/)
      end
    end

    context "with a custom strategy registered globally" do
      it "resolves it from DeltaCore.strategy_registry" do
        custom_strat = Module.new do
          def self.call(_snap, curr, _mapping)
            { added: curr, removed: [], modified: [] }
          end
        end

        DeltaCore.register_strategy(:custom_test, custom_strat)

        custom_mapping = DeltaCore::Mapping.new(:items, key: :id, fields: [], strategy: :custom_test)
        custom_config  = DeltaCore::Configuration.new
        custom_config.instance_variable_set(:@mappings, [custom_mapping])

        curr   = { items: [{ id: 1 }] }
        result = described_class.compare({}, curr, custom_config)
        expect(result.added.length).to eq(1)

        DeltaCore.strategy_registry.delete(:custom_test)
      end
    end

    context "with nested relations" do
      let(:config_with_relations) do
        mapping_with_rel = DeltaCore::Mapping.new(
          :items,
          key: :id,
          fields: [:qty],
          strategy: :quantity,
          relations: { prices: { key: :id, fields: [:amount], strategy: :replace } }
        )
        cfg = DeltaCore::Configuration.new
        cfg.instance_variable_set(:@mappings, [mapping_with_rel])
        cfg
      end

      it "compares nested collections" do
        snap   = { items: [{ id: 1, qty: 5, prices: [{ id: 10, amount: 100 }] }] }
        curr   = { items: [{ id: 1, qty: 5, prices: [{ id: 20, amount: 200 }] }] }
        result = described_class.compare(snap, curr, config_with_relations)
        expect(result.added.length + result.removed.length).to be > 0
      end

      context "when an entity exists only in current" do
        it "does not raise" do
          snap = {}
          curr = { items: [{ id: 1, qty: 5, prices: [{ id: 10, amount: 100 }] }] }
          expect { described_class.compare(snap, curr, config_with_relations) }.not_to raise_error
        end
      end
    end
  end
end
