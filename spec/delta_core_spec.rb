# frozen_string_literal: true

RSpec.describe DeltaCore do
  it "has a version number" do
    expect(DeltaCore::VERSION).not_to be_nil
  end

  describe "DSL configuration" do
    it "allows configuring a snapshot column"
    it "allows mapping associations with key, fields, and strategy"
    it "supports nested relation mapping"
  end

  describe "snapshot capture" do
    it "persists snapshot data only after external confirmation"
  end

  describe "delta computation" do
    it "returns added entities present in current state but absent from snapshot"
    it "returns removed entities present in snapshot but absent from current state"
    it "returns modified entities with changed field values"
    it "reports empty? when no differences exist"
  end
end
