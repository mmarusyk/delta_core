# frozen_string_literal: true

RSpec.describe DeltaCore::Strategies::Base do
  describe ".call" do
    it "raises NotImplementedError" do
      expect do
        described_class.call([], [], double("mapping"))
      end.to raise_error(NotImplementedError)
    end
  end

  describe ".index_by_key" do
    it "returns a hash keyed by the given field" do
      collection = [{ id: 1, qty: 5 }, { id: 2, qty: 3 }]
      result     = described_class.index_by_key(collection, :id)
      expect(result.keys).to contain_exactly(1, 2)
    end

    it "maps key value to the entity hash" do
      collection = [{ id: 1, qty: 5 }]
      result     = described_class.index_by_key(collection, :id)
      expect(result[1]).to eq({ id: 1, qty: 5 })
    end

    it "returns empty hash for empty collection" do
      expect(described_class.index_by_key([], :id)).to eq({})
    end

    it "last entry wins on duplicate keys" do
      collection = [{ id: 1, qty: 5 }, { id: 1, qty: 9 }]
      result     = described_class.index_by_key(collection, :id)
      expect(result[1][:qty]).to eq(9)
    end
  end
end
