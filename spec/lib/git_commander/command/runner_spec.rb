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

  it "provides access to the logger" do
    allow(GitCommander.logger).to receive(:info)
    command = GitCommander::Command.new(:wtf, output: output) do
      logger.info "hi"
    end
    runner = described_class.new(command)
    runner.run
    expect(GitCommander.logger).to have_received(:info).with("hi")
  end
end
