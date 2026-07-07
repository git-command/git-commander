# frozen_string_literal: true

require "spec_helper"

describe GitCommander::Plugin do
  it "initializes an Executor with the provided block" do
    source_instance = Object.new
    expect(described_class::Executor).to receive(:new).with(source_instance)
    described_class.new :git, source_instance: source_instance
  end

  describe "#find_command" do
    it "finds a loaded command by name" do
      plugin = described_class.new(:demo)
      command = GitCommander::Command.new(:"demo:setup")
      plugin.commands = [command]

      expect(plugin.find_command("demo:setup")).to eq command
    end

    it "raises CommandNotFound when the command is not defined by the plugin" do
      plugin = described_class.new(:demo)
      plugin.commands = []

      expect { plugin.find_command(:nope) }.to raise_error(described_class::CommandNotFound)
    end
  end
end
