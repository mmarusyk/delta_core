# frozen_string_literal: true

RSpec.describe DeltaCore::Strategies::Replace do
  let(:mapping) { DeltaCore::Mapping.new(:items, key: :id, fields: [:amount], strategy: :replace) }

  describe ".call" do
    context "when both collections are empty" do
      it "returns empty result" do
        result = described_class.call([], [], mapping)
        expect(result).to eq({ added: [], removed: [], modified: [] })
      end
    end

    context "when collections are identical" do
      it "returns empty result" do
        coll   = [{ id: 1, amount: 10 }]
        result = described_class.call(coll, coll, mapping)
        expect(result).to eq({ added: [], removed: [], modified: [] })
      end
    end

    context "when collections differ" do
      it "treats entire current as added and entire snapshot as removed" do
        snap   = [{ id: 1, amount: 10 }]
        curr   = [{ id: 2, amount: 20 }]
        result = described_class.call(snap, curr, mapping)
        expect(result[:added]).to eq(curr)
        expect(result[:removed]).to eq(snap)
        expect(result[:modified]).to eq([])
      end

      it "never produces modified entries" do
        snap   = [{ id: 1, amount: 5 }]
        curr   = [{ id: 1, amount: 9 }]
        result = described_class.call(snap, curr, mapping)
        expect(result[:modified]).to eq([])
      end
    end

    context "when snapshot is empty and current has items" do
      it "adds all items and removes none" do
        curr   = [{ id: 1, amount: 5 }]
        result = described_class.call([], curr, mapping)
        expect(result[:added]).to eq(curr)
        expect(result[:removed]).to eq([])
      end
    end

    context "when current is empty and snapshot has items" do
      it "removes all items and adds none" do
        snap   = [{ id: 1, amount: 5 }]
        result = described_class.call(snap, [], mapping)
        expect(result[:removed]).to eq(snap)
        expect(result[:added]).to eq([])
      end
    end
  end
end
