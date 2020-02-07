# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/git_commander/registry"

describe GitCommander::Registry do
  let(:registry) { described_class.new }

  it "allows registering commands" do
    expect(registry.commands[:wtf]).to_not be
    registry.register(:wtf)
    expect(registry.commands[:wtf]).to be
  end

  it "allows registering commands with arguments" do
    registry.register :wtf, arguments: [{ name: :first }, { name: :second }]
    wtf_command = registry.commands[:wtf]
    expect(wtf_command).to be
    expect(wtf_command.arguments).to eql(
      [
        GitCommander::Command::Option.new(name: :first, default: nil, description: nil),
        GitCommander::Command::Option.new(name: :second, default: nil, description: nil)
      ]
    )
  end

  it "allows registering commands with flags" do
    registry.register :wtf,
                      arguments: [{ name: :first }, { name: :second }],
                      flags: [{ name: "raise_hell", default: false }]
    wtf_command = registry.commands[:wtf]
    expect(wtf_command).to be
    expect(wtf_command.arguments).to eql(
      [
        GitCommander::Command::Option.new(name: :first, default: nil, description: nil),
        GitCommander::Command::Option.new(name: :second, default: nil, description: nil)
      ]
    )
    expect(wtf_command.flags).to eql(
      [GitCommander::Command::Option.new(name: :raise_hell, default: false)]
    )
  end

  it "allows registering commands with switches" do
    registry.register :wtf,
                      arguments: [{ name: :first }, { name: :second }],
                      flags: [{ name: "raise_hell", default: false }],
                      switches: [{ name: "clobber", default: true }]
    wtf_command = registry.commands[:wtf]
    expect(wtf_command).to be
    expect(wtf_command.arguments).to eql(
      [
        GitCommander::Command::Option.new(name: :first, default: nil, description: nil),
        GitCommander::Command::Option.new(name: :second, default: nil, description: nil)
      ]
    )
    expect(wtf_command.flags).to eql(
      [GitCommander::Command::Option.new(name: :raise_hell, default: false)]
    )
    expect(wtf_command.switches).to eql(
      [GitCommander::Command::Option.new(name: :clobber, default: true)]
    )
  end

  it "allows describing a command" do
    registry.register(:wtf, summary: "WTF yo", description: "WTF is up with x")
    wtf_command = registry.commands[:wtf]
    expect(wtf_command).to be
    expect(wtf_command.summary).to eq("WTF yo")
    expect(wtf_command.description).to eq("WTF is up with x")
  end

  it "allows registering pre-built commands" do
    command = GitCommander::Command.new(:wtf)
    registry.register_command command
    expect(registry.commands[:wtf]).to eq(command)
  end

  it "allows re-registering existing commands" do
    registry.register(:wtf, arguments: [{ name: :day, default: :today }])
    wtf_command = registry.commands[:wtf]
    expect(wtf_command.arguments).to eql(
      [GitCommander::Command::Option.new(name: :day, default: :today, description: nil)]
    )
    registry.register(:wtf, arguments: [{ name: :message }])
    expect(registry.find(:wtf).arguments).to eq(
      [GitCommander::Command::Option.new(name: :message, default: nil, description: nil)]
    )
  end

  it "allows looking up a registered command" do
    expected_command = registry.register(:wtf)
    expect(registry.find(:wtf)).to eq expected_command
  end

  it "raises an error when trying to find a command that is not registered" do
    expect { registry.find(:wtf) }.to raise_error GitCommander::Registry::CommandNotFound
  end

  it "allows registering pre-built plugins" do
    plugin = GitCommander::Plugin.new(:wtf)
    registry.register_plugin plugin
    expect(registry.plugins[:wtf]).to eq(plugin)
  end

  describe "#load(loader, options = {})" do
    it "uses the provided loader to load the given options" do
      options = { content: "command :hello do |cmd|; cmd.on_run { say 'hello' }; end" }
      loader_class_spy = spy("loader class")
      loader_instance_spy = spy("loader instance")

      expect(loader_class_spy).to receive(:new).with(registry).and_return(loader_instance_spy)
      expect(loader_instance_spy).to receive(:load).with(options)

      registry.load(loader_class_spy, options)
    end

    it "registers commands that are successfully loaded" do
      options = { content: "command :hello do |cmd|; cmd.on_run { say 'hello' }; end" }
      loader_class_spy = spy("loader class")
      loader_instance_spy = spy("loader instance")
      results = GitCommander::LoaderResult.new
      results.commands = [GitCommander::Command.new(:hello)]

      expect(loader_class_spy).to receive(:new).with(registry).and_return(loader_instance_spy)
      expect(loader_instance_spy).to receive(:load).with(options).and_return(results)
      results.commands.each do |cmd|
        expect(registry).to receive(:register_command).with(cmd)
      end

      registry.load(loader_class_spy, options)
    end

    it "registers plugins that are successfully loaded" do
      options = { content: "plugin :git;" }
      loader_class_spy = spy("loader class")
      loader_instance_spy = spy("loader instance")
      results = GitCommander::LoaderResult.new
      results.plugins = [GitCommander::Plugin.new(:git)]

      expect(loader_class_spy).to receive(:new).with(registry).and_return(loader_instance_spy)
      expect(loader_instance_spy).to receive(:load).with(options).and_return(results)
      results.plugins.each do |plugin|
        expect(registry).to receive(:register_plugin).with(plugin)
      end

      registry.load(loader_class_spy, options)
    end
  end
end
