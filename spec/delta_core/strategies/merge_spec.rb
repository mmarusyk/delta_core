# frozen_string_literal: true

RSpec.describe DeltaCore::Strategies::Merge do
  let(:mapping) { DeltaCore::Mapping.new(:items, key: :id, fields: %i[amount type], strategy: :merge) }

  describe ".call" do
    context "when both collections are empty" do
      it "returns empty result" do
        result = described_class.call([], [], mapping)
        expect(result).to eq({ added: [], removed: [], modified: [] })
      end
    end

    context "when current has items not in snapshot" do
      it "identifies added items" do
        curr   = [{ id: 1, amount: 10, type: "charge" }]
        result = described_class.call([], curr, mapping)
        expect(result[:added]).to eq(curr)
        expect(result[:removed]).to eq([])
        expect(result[:modified]).to eq([])
      end
    end

    context "when snapshot has items not in current" do
      it "identifies removed items" do
        snap   = [{ id: 1, amount: 10, type: "charge" }]
        result = described_class.call(snap, [], mapping)
        expect(result[:removed]).to eq(snap)
        expect(result[:added]).to eq([])
        expect(result[:modified]).to eq([])
      end
    end

    context "when no fields differ" do
      it "does not report modified" do
        item   = { id: 1, amount: 10, type: "charge" }
        result = described_class.call([item], [item], mapping)
        expect(result[:modified]).to eq([])
      end
    end

    context "when one field differs" do
      let(:snap) { [{ id: 1, amount: 10, type: "charge" }] }
      let(:curr) { [{ id: 1, amount: 20, type: "charge" }] }

      it "reports modified with the changed field listed" do
        result = described_class.call(snap, curr, mapping)
        expect(result[:modified].length).to eq(1)
        expect(result[:modified].first[:changed_fields]).to eq([:amount])
      end

      it "includes current and snapshot in the modified entry" do
        result = described_class.call(snap, curr, mapping)
        entry  = result[:modified].first
        expect(entry[:current]).to eq({ id: 1, amount: 20, type: "charge" })
        expect(entry[:snapshot]).to eq({ id: 1, amount: 10, type: "charge" })
      end
    end

    context "when multiple fields differ" do
      it "reports all changed fields" do
        snap   = [{ id: 1, amount: 10, type: "charge" }]
        curr   = [{ id: 1, amount: 20, type: "refund" }]
        result = described_class.call(snap, curr, mapping)
        expect(result[:modified].first[:changed_fields]).to contain_exactly(:amount, :type)
      end
    end

    context "with added, removed, and modified items mixed together" do
      it "handles all three cases in one call" do
        snap   = [{ id: 1, amount: 10, type: "a" }, { id: 2, amount: 5, type: "b" }]
        curr   = [{ id: 1, amount: 99, type: "a" }, { id: 3, amount: 7, type: "c" }]
        result = described_class.call(snap, curr, mapping)
        expect(result[:added].map { |r| r[:id] }).to eq([3])
        expect(result[:removed].map { |r| r[:id] }).to eq([2])
        expect(result[:modified].length).to eq(1)
      end
    end
  end
end
