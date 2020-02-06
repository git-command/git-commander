# frozen_string_literal: true

require "spec_helper"

RSpec.describe GitCommander::LoaderResult do
  describe "#success?" do
    it "returns true if no errors are presesnt" do
      result = described_class.new
      expect(result.success?).to be_truthy
    end

    it "returns false if errors are present" do
      result = described_class.new
      result.errors << GitCommander::Registry::LoadError.new

      expect(result.success?).to be_falsey
    end
  end

  describe "#errors" do
    it "returns any errors added to it" do
      result = described_class.new
      expected_error = instance_double(GitCommander::Registry::LoadError)
      result.errors << expected_error

      expect(result.errors).to include expected_error
    end
  end
end
