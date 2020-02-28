# frozen_string_literal: true

require "spec_helper"

RSpec.describe GitCommander::Command::Loaders::Raw do
  let(:registry) { GitCommander::Registry.new }
  let(:loader) { described_class.new(registry) }

  describe "#load" do
    it "returns a Result" do
      expect(loader.load).to be_a GitCommander::LoaderResult
    end

    it "registers commands defined in the provided string with the registry" do
      raw_command_string = <<~COMMANDS
        command :hello do |cmd = nil|
          cmd.summary "Outputs a greeting."
          cmd.description "This is way too much information about a simple greeting."
          cmd.argument :greeting, default: "Hello"
          cmd.argument :name, default: ""
          cmd.flag :as_question, default: false
          cmd.switch :loud, default: false

          cmd.on_run do |options|
            response = options[:greeting].dup
            response += ", \#{options[:name]}" unless options[:name].to_s.empty?
            response.upcase! if options[:loud]
            response += options[:as_question] ? "?" : "."
            say response
          end
        end

        command :love do
        end
      COMMANDS

      expect(loader.result.commands).to be_empty

      loader.load(raw_command_string)

      expect(loader.result.commands.size).to eq 2

      loader.result.commands.each do |command|
        expect(command.registry).to eq registry
      end

      registered_command = loader.result.commands.first
      expect(registered_command.summary).to eq "Outputs a greeting."
      expect(registered_command.description).to eq "This is way too much information about a simple greeting."
      expect(registered_command.arguments.size).to eq 2
      expect(registered_command.arguments.first.name).to eq :greeting
      expect(registered_command.arguments.first.default).to eq "Hello"
      expect(registered_command.arguments.last.name).to eq :name
      expect(registered_command.arguments.last.default).to eq ""
      expect(registered_command.flags.size).to eq 1
      expect(registered_command.flags.first.name).to eq :as_question
      expect(registered_command.flags.first.default).to eq false
      expect(registered_command.switches.size).to eq 1
      expect(registered_command.switches.first.name).to eq :loud
      expect(registered_command.switches.first.default).to eq false

      output = spy("output")
      registered_command.output = output

      registered_command.run [
        GitCommander::Command::Option.new(name: :greeting, value: "Salutations"),
        GitCommander::Command::Option.new(name: :loud, value: true)
      ]
      expect(output).to have_received(:puts).with "SALUTATIONS."
    end

    it "rescues syntax errors and reports them in the LoaderResult" do
      raw_command_string = <<~COMMANDS
        command :hello d |cmd = nil|
          cmd.danger!
        end
      COMMANDS

      result = loader.load(raw_command_string)
      expect(result).to_not be_success

      resulting_error = result.errors.first
      expect(resulting_error).to be_kind_of described_class::CommandParseError
      expect(resulting_error.message).to include "syntax error"
      expect(resulting_error.backtrace).to_not be_empty
    end

    it "rescues errors from improperly defined commands and reports them in the LoaderResult" do
      raw_command_string = <<~COMMANDS
        command :hello do |cmd = nil|
          cmd.danger!
        end
      COMMANDS

      result = loader.load(raw_command_string)
      expect(result).to_not be_success

      resulting_error = result.errors.first
      expect(resulting_error).to be_kind_of GitCommander::Command::Configurator::ConfigurationError
      expect(resulting_error.message).to include "undefined method \`danger!"
      expect(resulting_error.backtrace).to_not be_empty
    end

    context "with plugins" do
      it "registers comamnds with native plugins" do
        raw_command_string = <<~COMMANDS
          plugin :git

          command :local_branches do |cmd = nil|
            cmd.on_run do |options|
              say git.branches.local.map(&:name)
            end
          end

          command :love do
          end
        COMMANDS

        native_plugin_loader_spy = spy("Native Plugin Loader")
        native_plugin_loader_result = GitCommander::LoaderResult.new
        native_plugin_loader_result.plugins << GitCommander::Plugin.new(:git, registry: registry)
        expect(loader.result.commands).to be_empty
        expect(GitCommander::Plugin::Loader).to receive(:new).with(registry).and_return(native_plugin_loader_spy)
        expect(native_plugin_loader_spy).to receive(:load).with(:git, {}).and_return(native_plugin_loader_result)

        loader.load(raw_command_string)

        expect(loader.result.plugins.size).to eq 1
        expect(loader.result.commands.size).to eq 2

        (loader.result.commands + loader.result.plugins).flatten.each do |command_or_plugin|
          expect(command_or_plugin.registry).to eq registry
        end

        registered_command = loader.result.commands.first
        output = spy("output")
        registered_command.output = output
      end
    end
  end
end
