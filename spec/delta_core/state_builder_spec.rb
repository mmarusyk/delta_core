# frozen_string_literal: true

RSpec.describe DeltaCore::StateBuilder do
  ItemDouble  = Struct.new(:product_id, :quantity, :unit_price, keyword_init: true)
  PriceDouble = Struct.new(:id, :amount, keyword_init: true)

  let(:config) do
    cfg = DeltaCore::Configuration.new
    cfg.map(:items, key: :product_id, fields: %i[quantity unit_price], strategy: :quantity)
    cfg
  end

  let(:model) { double("model") }

  describe ".build" do
    it "returns a Hash keyed by mapping name symbol" do
      allow(model).to receive(:items).and_return([])
      result = described_class.build(model, config)
      expect(result).to be_a(Hash)
      expect(result.keys).to include(:items)
    end

    it "returns empty array for empty association" do
      allow(model).to receive(:items).and_return([])
      expect(described_class.build(model, config)[:items]).to eq([])
    end

    it "includes key field and configured fields in each record hash" do
      item = ItemDouble.new(product_id: 1, quantity: 3, unit_price: 10)
      allow(model).to receive(:items).and_return([item])
      record = described_class.build(model, config)[:items].first
      expect(record[:product_id]).to eq(1)
      expect(record[:quantity]).to eq(3)
      expect(record[:unit_price]).to eq(10)
    end

    it "sorts records by key field ascending" do
      items = [
        ItemDouble.new(product_id: 3, quantity: 1, unit_price: 1),
        ItemDouble.new(product_id: 1, quantity: 2, unit_price: 2),
        ItemDouble.new(product_id: 2, quantity: 3, unit_price: 3)
      ]
      allow(model).to receive(:items).and_return(items)
      result = described_class.build(model, config)[:items]
      expect(result.map { |r| r[:product_id] }).to eq([1, 2, 3])
    end

    it "includes nil field values in the record" do
      item = ItemDouble.new(product_id: 1, quantity: nil, unit_price: 5)
      allow(model).to receive(:items).and_return([item])
      record = described_class.build(model, config)[:items].first
      expect(record[:quantity]).to be_nil
    end

    it "handles multiple mappings" do
      cfg = DeltaCore::Configuration.new
      cfg.map(:items, key: :product_id, fields: [:quantity], strategy: :quantity)
      cfg.map(:charges, key: :id, fields: [:amount], strategy: :replace)

      charge_double = Struct.new(:id, :amount, keyword_init: true)
      allow(model).to receive_messages(items: [], charges: [charge_double.new(id: 1, amount: 50)])

      result = described_class.build(model, cfg)
      expect(result.keys).to include(:items, :charges)
      expect(result[:charges].first[:amount]).to eq(50)
    end

    context "with nested relations" do
      let(:config_with_relations) do
        cfg = DeltaCore::Configuration.new
        cfg.map(:items, key: :product_id, fields: [:quantity], strategy: :quantity,
                        relations: { prices: { key: :id, fields: [:amount], strategy: :replace } })
        cfg
      end

      it "includes nested association in the record hash" do
        price = PriceDouble.new(id: 10, amount: 99)
        item  = double("item", product_id: 1, quantity: 2, prices: [price])
        allow(model).to receive(:items).and_return([item])
        record = described_class.build(model, config_with_relations)[:items].first
        expect(record[:prices]).to be_an(Array)
        expect(record[:prices].first[:amount]).to eq(99)
      end

      it "sorts nested records by nested key" do
        prices = [
          PriceDouble.new(id: 3, amount: 30),
          PriceDouble.new(id: 1, amount: 10)
        ]
        item = double("item", product_id: 1, quantity: 2, prices: prices)
        allow(model).to receive(:items).and_return([item])
        nested = described_class.build(model, config_with_relations)[:items].first[:prices]
        expect(nested.map { |p| p[:id] }).to eq([1, 3])
      end
    end

    context "with extensions" do
      let(:ext) do
        ->(entity, _record, _mapping) { entity.merge(extra: true) }
      end

      before  { described_class.extensions << ext }
      after   { described_class.extensions.delete(ext) }

      it "applies extensions to each entity" do
        item = ItemDouble.new(product_id: 1, quantity: 1, unit_price: 5)
        allow(model).to receive(:items).and_return([item])
        record = described_class.build(model, config)[:items].first
        expect(record[:extra]).to be(true)
      end

      it "skips non-callable extensions gracefully" do
        described_class.extensions << "not_callable"
        item = ItemDouble.new(product_id: 1, quantity: 1, unit_price: 5)
        allow(model).to receive(:items).and_return([item])
        expect { described_class.build(model, config) }.not_to raise_error
        described_class.extensions.delete("not_callable")
      end
    end
  end
end
