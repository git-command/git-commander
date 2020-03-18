# frozen_string_literal: true

require "spec_helper"

RSpec.describe GitCommander::Loader do
  describe "#load" do
    let(:loader) { described_class.new GitCommander::Registry.new }

    it "raises a NotImplementedError" do
      expect { loader.load }.to raise_error NotImplementedError
    end

    it "provides access to running system commands" do
      expected_command_string = 'echo "Good vibrations"'
      expect(GitCommander::System).to receive(:run).with(expected_command_string)
      loader.system.run expected_command_string
    end

    it "allows output to the system" do
      expected_output = "Good vibrations"
      expect(GitCommander::System).to receive(:say).with(expected_output)
      loader.system.say expected_output
    end
  end
end
