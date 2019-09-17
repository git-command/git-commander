# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/git_commander/cli"

describe GitCommander::CLI do
  let(:cli) { described_class.new(output: output, registry: registry) }
  let(:registry) { GitCommander::Registry.new }
  let(:output) { spy("output") }
  let(:logger) { Logger.new("tmp/kenny-loggins.log") }

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
    command = GitCommander::Command.new :zombie, output: output
    expect(registry).to receive(:find).with(target_command).and_return(command)
    expect(command).to receive(:run)
    expect(cli).to_not receive(:help)

    cli.run target_command
  end

  it "runs registered commands with arguments" do
    target_command = "wtf"
    arguments = ["What's up with that?", "And this?"]
    command = GitCommander::Command.new :zombie, arguments: [{ name: :this }, { name: :that }], output: output
    expect(registry).to receive(:find).with(target_command).and_return(command)
    expect(command).to receive(:run).with(this: arguments.first, that: arguments.last)
    expect(cli).to_not receive(:help)

    cli.run [target_command, *arguments]
  end

  it "runs registered commands with options" do
    command = GitCommander::Command.new(
      :zombie,
      flags: [{ name: :question, default: "What's up with that?" }],
      output: output
    )
    expect(registry).to receive(:find).with("zombie").and_return(command)
    expect(command).to receive(:run).with(question: "Yo dawg, zombies?")
    expect(cli).to_not receive(:help)

    cli.run ["zombie", "--question", "Yo dawg, zombies?"]
  end

  it "runs registered commands with options using defaults" do
    command = GitCommander::Command.new(
      :zombie,
      flags: [{ name: :question, default: "What's up with that?" }],
      output: output
    )
    expect(registry).to receive(:find).with("zombie").and_return(command)
    expect(command).to receive(:run).with(question: "What's up with that?")
    expect(cli).to_not receive(:help)

    cli.run ["zombie"]
  end

  it "runs registered commands with arguments and options" do
    arguments = ["What's up with that?", "And this?"]
    command = GitCommander::Command.new(
      :zombie,
      arguments: [{ name: :this }, { name: :that }],
      flags: [{ name: :question, default: "What's up with that?" }],
      switches: [{ name: :auto_answer, default: false }],
      output: output
    )
    expect(registry).to receive(:find).with("zombie").and_return(command)
    expect(command).to receive(:run).with(
      this: arguments.first,
      that: arguments.last,
      question: "Yo dawg, zombies?",
      auto_answer: true
    )
    expect(cli).to_not receive(:help)

    cli.run ["zombie", "-q", "Yo dawg, zombies?", "--auto-answer", *arguments]
  end
end
