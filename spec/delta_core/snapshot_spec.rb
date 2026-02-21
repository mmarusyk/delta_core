# frozen_string_literal: true

RSpec.describe DeltaCore::Snapshot do
  describe "FORMAT_VERSION" do
    it "equals 1" do
      expect(described_class::FORMAT_VERSION).to eq(1)
    end
  end

  describe "#initialize / #state" do
    context "with nil input" do
      it "returns empty hash" do
        expect(described_class.new(nil).state).to eq({})
      end
    end

    context "with an empty string" do
      it "returns empty hash" do
        expect(described_class.new("").state).to eq({})
      end
    end

    context "with a whitespace-only string" do
      it "returns empty hash" do
        expect(described_class.new("   ").state).to eq({})
      end
    end

    context "with JSON null" do
      it "returns empty hash" do
        expect(described_class.new("null").state).to eq({})
      end
    end

    context "with invalid JSON" do
      it "returns empty hash" do
        expect(described_class.new("not_json{{{").state).to eq({})
      end
    end

    context "when only the version key is present" do
      it "returns empty hash" do
        expect(described_class.new('{"_v":1}').state).to eq({})
      end
    end

    context "with no arguments" do
      it "returns empty hash" do
        expect(described_class.new.state).to eq({})
      end
    end

    it "strips the _v key from state" do
      raw = '{"_v":1,"items":[]}'
      expect(described_class.new(raw).state.keys).not_to include(:_v)
    end

    it "parses with symbol keys" do
      raw   = '{"_v":1,"items":[{"id":1}]}'
      state = described_class.new(raw).state
      expect(state.keys).to include(:items)
    end

    it "parses nested data correctly" do
      raw   = '{"_v":1,"items":[{"id":1,"qty":5}]}'
      state = described_class.new(raw).state
      expect(state[:items]).to eq([{ id: 1, qty: 5 }])
    end
  end

  describe "#empty?" do
    context "with nil input" do
      it "returns true" do
        expect(described_class.new(nil)).to be_empty
      end
    end

    context "when JSON contains only the version key" do
      it "returns true" do
        expect(described_class.new('{"_v":1}')).to be_empty
      end
    end

    context "when state has content" do
      it "returns false" do
        raw = '{"_v":1,"items":[{"id":1}]}'
        expect(described_class.new(raw)).not_to be_empty
      end
    end
  end

  describe "#serialize" do
    subject(:snapshot) { described_class.new }

    it "returns a JSON string" do
      result = snapshot.serialize({})
      expect(result).to be_a(String)
    end

    it "produces valid JSON" do
      expect { JSON.parse(snapshot.serialize({})) }.not_to raise_error
    end

    it "includes the _v key in the envelope" do
      result = snapshot.serialize({})
      parsed = JSON.parse(result)
      expect(parsed["_v"]).to eq(1)
    end

    it "stringifies top-level symbol keys" do
      result = snapshot.serialize({ items: [] })
      parsed = JSON.parse(result)
      expect(parsed.keys).to include("items")
    end

    it "preserves the collection data" do
      state  = { items: [{ id: 1, qty: 5 }] }
      result = snapshot.serialize(state)
      parsed = JSON.parse(result)
      expect(parsed["items"]).to eq([{ "id" => 1, "qty" => 5 }])
    end

    it "roundtrip: serialize then parse produces the same state" do
      original   = { items: [{ id: 1, qty: 5 }] }
      serialized = snapshot.serialize(original)
      restored   = described_class.new(serialized).state
      expect(restored[:items]).to eq([{ id: 1, qty: 5 }])
    end
  end
end
