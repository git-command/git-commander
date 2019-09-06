# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/git_commander/cli"

describe GitCommander::CLI do
  let(:cli) { described_class.new(output: output, registry: registry) }
  let(:registry) { GitCommander::Registry.new }
  let(:output) { spy("output") }
  let(:logger) { instance_double GitCommander::Logger, info: true, debug: true, error: true }

  before do
    allow(GitCommander).to receive(:logger).and_return(logger)
  end

  it "displays a help message when no command is given" do
    expect(cli).to receive(:help)
    cli.run
  end

  context "when the help command is given" do
    it "includes the GitCommander version number in the help message" do
      cli.run "help"
      expect(output).to have_received(:puts).with "VERSION"
      expect(output).to have_received(:puts).with "    #{GitCommander::VERSION}"
    end
  end

  it "displays a help message when the given command is not registerd" do
    expect(cli).to receive(:help)
    cli.run :nope
  end

  it "runs registered commands without arguments" do
    target_command = "bobo"
    mock_command = instance_double(GitCommander::Command)
    expect(registry).to receive(:find).with(target_command).and_return(mock_command)
    expect(mock_command).to receive(:run)
    expect(cli).to_not receive(:help)

    cli.run target_command
  end

  it "runs registered commands with arguments"
  it "runs registered commands with options"
  it "runs registered commands with arguments and options"
end
