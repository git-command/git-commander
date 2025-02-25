# frozen_string_literal: true

require "spec_helper"

RSpec.describe GitCommander::Plugin::Loader do
  let(:registry) { GitCommander::Registry.new }
  let(:loader) { described_class.new(registry) }

  describe ".load(name)" do
    it "returns a Plugin" do
      expect(loader.load(:system)).to be_a GitCommander::Plugin
    end

    it "loads native plugins" do
      result = loader.load(:system)

      expect(registry).to be_valid

      expect(result.name).to eq :system
      expect(result.executor).to respond_to(:run)
    end

    it "loads commands for the plugin" do
      allow(File).to receive(:read).and_return(
        <<~COMMAND
          require 'ostruct'

          command :hello do |cmd|
            cmd.on_run { say "hello" }
          end

          command :blank do |cmd|
          end

          OpenStruct.new(run: true)
        COMMAND
      )

      plugin = loader.load(:plugin_with_commands)

      expect(plugin.registry).to be_valid

      expect(plugin.name).to eq :plugin_with_commands
      expect(plugin.registry.commands.size).to eq 2
      expect(plugin.registry.commands[:"plugin-with-commands:hello"]).to be
      expect(plugin.registry.commands[:"plugin-with-commands:blank"]).to be
      expect(plugin.executor).to respond_to(:run)
    end

    it "reports LoadError if the native plugin doesn't exist" do
      plugin = loader.load(:bubbles)

      expect(plugin.registry).to_not be_valid

      resulting_error = plugin.registry.errors[:plugins][:bubbles].first
      expect(resulting_error).to be_kind_of described_class::LoadError
      expect(resulting_error.message).to include "No such file or directory"
      expect(resulting_error.backtrace).to_not be_empty
    end

    it "reports LoadError if there's a problem reading the native plugin" do
      allow(File).to receive(:read).and_raise Errno::EACCES
      plugin = loader.load(:bubbles)

      expect(plugin.registry).to_not be_valid

      resulting_error = plugin.registry.errors[:plugins][:bubbles].first
      expect(resulting_error).to be_kind_of described_class::LoadError
      expect(resulting_error.message).to include "Permission denied"
      expect(resulting_error.backtrace).to_not be_empty
    end

    it "reports Configurator::ConfigurationError if a plugin command cannot be parsed" do
      allow(File).to receive(:read).and_return(
        <<~COMMAND
          command :danger do |cmd|
            cmd.danger!
          end
        COMMAND
      )

      result = loader.load(:danger)

      expect(result.registry).not_to be_valid

      resulting_error = result.registry.errors[:plugins][:danger].first
      expect(resulting_error).to be_kind_of GitCommander::Command::Configurator::ConfigurationError
      expect(resulting_error.message).to include "undefined method"
      expect(resulting_error.backtrace).to_not be_empty
    end
  end
end
