# frozen_string_literal: true

require "spec_helper"

RSpec.describe GitCommander::Plugin::Loader do
  let(:registry) { GitCommander::Registry.new }
  let(:loader) { described_class.new(registry) }

  describe ".load(name, path:, url:)" do
    it "returns a Result" do
      expect(loader.load(:git)).to be_a GitCommander::LoaderResult
    end

    it "loads the plugins result with matching native plugin" do
      result = loader.load(:git)

      expect(result).to be_success

      plugin = result.plugins.first
      expect(plugin.name).to eq :git
      expect(plugin.executor).to respond_to(:branches)
    end

    it "reports NotFound if the native plugin doesn't exist" do
      result = loader.load(:bubbles)

      expect(result).to_not be_success

      resulting_error = result.errors.first
      expect(resulting_error).to be_kind_of described_class::LoadError
      expect(resulting_error.message).to include "No such file or directory"
      expect(resulting_error.backtrace).to_not be_empty
    end

    it "reports LoadError if there's a problem reading the native plugin" do
      allow(File).to receive(:read).and_raise Errno::EACCES
      result = loader.load(:bubbles)

      expect(result).to_not be_success

      resulting_error = result.errors.first
      expect(resulting_error).to be_kind_of described_class::NotFoundError
      expect(resulting_error.message).to include "Permission denied"
      expect(resulting_error.backtrace).to_not be_empty
    end
  end
end
