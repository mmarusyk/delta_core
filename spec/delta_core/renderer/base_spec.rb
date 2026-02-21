# frozen_string_literal: true

RSpec.describe DeltaCore::Renderer::Base do
  let(:renderer_class) do
    Class.new do
      include DeltaCore::Renderer::Base
    end
  end

  let(:renderer) { renderer_class.new }
  let(:delta)    { DeltaCore::DeltaResult.new(added: [1]) }

  describe "#call" do
    it "raises NotImplementedError" do
      expect { renderer.call(delta) }.to raise_error(NotImplementedError)
    end
  end

  describe "DeltaResult#render integration" do
    it "passes the delta_result to a custom renderer" do
      custom = Class.new do
        include DeltaCore::Renderer::Base

        def call(result)
          result.added.length
        end
      end.new

      expect(delta.render(custom)).to eq(1)
    end
  end
end
