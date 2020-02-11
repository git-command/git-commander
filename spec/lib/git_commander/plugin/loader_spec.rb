# frozen_string_literal: true

require "spec_helper"

RSpec.describe GitCommander::Plugin::Loader do
  let(:registry) { GitCommander::Registry.new }
  let(:loader) { described_class.new(registry) }

  describe ".load(name)" do
    it "returns a Result" do
      expect(loader.load(:system)).to be_a GitCommander::LoaderResult
    end

    it "loads the plugins result with matching native plugin" do
      result = loader.load(:system)

      expect(result).to be_success

      plugin = result.plugins.first
      expect(plugin.name).to eq :system
      expect(plugin.executor).to respond_to(:run)
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

      result = loader.load(:plugin_with_commands)

      expect(result).to be_success

      plugin = result.plugins.first
      expect(plugin.name).to eq :plugin_with_commands
      expect(plugin.commands.size).to eq 2
      expect(plugin.executor).to respond_to(:run)
    end

    it "reports NotFound if the native plugin doesn't exist" do
      result = loader.load(:bubbles)

      expect(result).to_not be_success

      resulting_error = result.errors.first
      expect(resulting_error).to be_kind_of described_class::LoadError
      expect(resulting_error.message).to include "No such file or directory"
      expect(resulting_error.backtrace).to_not be_empty
    end

    it "reports LoadError if there's a problem reading the native plugin" do
      allow(File).to receive(:read).and_raise Errno::EACCES
      result = loader.load(:bubbles)

      expect(result).to_not be_success

      resulting_error = result.errors.first
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

      expect(result).to_not be_success

      resulting_error = result.errors.first
      expect(resulting_error).to be_kind_of GitCommander::Command::Configurator::ConfigurationError
      expect(resulting_error.message).to include "undefined method"
      expect(resulting_error.backtrace).to_not be_empty
    end
  end
end
