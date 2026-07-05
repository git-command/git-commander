# frozen_string_literal: true

require "spec_helper"

describe GitCommander::Command::Runner do
  let(:output) { spy("output") }

  it "evalutes the provided command's block in the context of this class" do
    command = GitCommander::Command.new(:wtf, output: output, switches: [{ name: :loud }]) do
      say "I'm on a boat!"
    end
    runner = described_class.new(command)
    expect(runner).to receive(:instance_exec).with(loud: true)
    runner.run loud: true
  end

  it "allows adding to the command's output" do
    command = GitCommander::Command.new(:wtf, output: output) do
      say "I'm on a boat!"
    end
    runner = described_class.new(command)
    runner.run
    expect(output).to have_received(:puts).with "I'm on a boat!"
  end

  it "resolves each referenced plugin to its own executor" do
    registry = GitCommander::Registry.new
    registry.register_plugin GitCommander::Plugin.new(:alpha, source_instance: "alpha instance")
    registry.register_plugin GitCommander::Plugin.new(:beta, source_instance: "beta instance")
    command = GitCommander::Command.new(:wtf, output: output, registry: registry) do
      say alpha.to_s
      say beta.to_s
    end

    described_class.new(command).run

    expect(output).to have_received(:puts).with "alpha instance"
    expect(output).to have_received(:puts).with "beta instance"
  end
end
