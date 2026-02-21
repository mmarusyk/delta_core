# frozen_string_literal: true

RSpec.describe DeltaCore::Strategies::Quantity do
  let(:mapping) { DeltaCore::Mapping.new(:items, key: :id, fields: [:qty], strategy: :quantity) }

  describe ".call" do
    let(:multi_mapping) do
      DeltaCore::Mapping.new(:items, key: :id, fields: %i[qty price], strategy: :quantity)
    end

    context "when both collections are empty" do
      it "returns empty result" do
        result = described_class.call([], [], mapping)
        expect(result).to eq({ added: [], removed: [], modified: [] })
      end
    end

    context "when current has items not in snapshot" do
      it "identifies added items" do
        curr   = [{ id: 1, qty: 5 }]
        result = described_class.call([], curr, mapping)
        expect(result[:added]).to eq([{ id: 1, qty: 5 }])
        expect(result[:removed]).to eq([])
        expect(result[:modified]).to eq([])
      end
    end

    context "when snapshot has items not in current" do
      it "identifies removed items" do
        snap   = [{ id: 1, qty: 5 }]
        result = described_class.call(snap, [], mapping)
        expect(result[:removed]).to eq([{ id: 1, qty: 5 }])
        expect(result[:added]).to eq([])
        expect(result[:modified]).to eq([])
      end
    end

    context "when qty differs" do
      let(:snap) { [{ id: 1, qty: 5 }] }
      let(:curr) { [{ id: 1, qty: 10 }] }

      it "identifies modified items" do
        result = described_class.call(snap, curr, mapping)
        expect(result[:modified].length).to eq(1)
        expect(result[:modified].first[:current][:qty]).to eq(10)
        expect(result[:modified].first[:snapshot][:qty]).to eq(5)
      end

      it "does not include changed_fields key in the modified entry" do
        result = described_class.call(snap, curr, mapping)
        expect(result[:modified].first.keys).not_to include(:changed_fields)
      end
    end

    context "when qty is equal" do
      it "does not report modified" do
        snap   = [{ id: 1, qty: 5 }]
        curr   = [{ id: 1, qty: 5 }]
        result = described_class.call(snap, curr, mapping)
        expect(result[:modified]).to eq([])
      end
    end

    context "with multiple fields when any field differs" do
      it "reports modified" do
        snap   = [{ id: 1, qty: 5, price: 10 }]
        curr   = [{ id: 1, qty: 5, price: 20 }]
        result = described_class.call(snap, curr, multi_mapping)
        expect(result[:modified].length).to eq(1)
      end
    end

    context "with multiple fields when all fields are equal" do
      it "does not report modified" do
        snap   = [{ id: 1, qty: 5, price: 10 }]
        curr   = [{ id: 1, qty: 5, price: 10 }]
        result = described_class.call(snap, curr, multi_mapping)
        expect(result[:modified]).to eq([])
      end
    end

    context "with added, removed, and modified items mixed together" do
      it "handles all three cases in one call" do
        snap   = [{ id: 1, qty: 5 }, { id: 2, qty: 3 }]
        curr   = [{ id: 1, qty: 8 }, { id: 3, qty: 1 }]
        result = described_class.call(snap, curr, mapping)
        expect(result[:added].map { |r| r[:id] }).to eq([3])
        expect(result[:removed].map { |r| r[:id] }).to eq([2])
        expect(result[:modified].length).to eq(1)
      end
    end
  end
end
