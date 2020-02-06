# frozen_string_literal: true

require "spec_helper"

RSpec.describe GitCommander::Command::Loaders::Base do
  describe "#load" do
    it "raises a NotImplementedError" do
      expect { described_class.new(GitCommander::Registry.new).load }.to raise_error NotImplementedError
    end
  end
end
