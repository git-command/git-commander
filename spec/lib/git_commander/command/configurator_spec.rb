# frozen_string_literal: true

require "spec_helper"

describe GitCommander::Command::Configurator do
  let(:registry) { GitCommander::Registry.new }
  let(:configurator) { described_class.new(registry) }

  describe "#configure(command_name, &block)" do
    it "returns a Command" do
      expect(configurator.configure(:hi)).to be_a GitCommander::Command
    end

    it "registers commands defined in the provided string with the registry" do
      registered_command = configurator.configure(:hello) do |cmd|
        cmd.summary "Outputs a greeting."
        cmd.description "This is way too much information about a simple greeting."
        cmd.argument :greeting, default: "Hello"
        cmd.argument :name, default: ""
        cmd.flag :as_question, default: false
        cmd.switch :loud, default: false

        cmd.helper :yell do |saying|
          say saying.to_s.upcase
        end

        cmd.helper :woot do
          yell :woot
        end

        cmd.on_run do |options|
          response = options[:greeting].dup
          response += ", \#{options[:name]}" unless options[:name].to_s.empty?
          response.upcase! if options[:loud]
          response += options[:as_question] ? "?" : "."
          say response
        end
      end

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

    it "allows setting a helper method" do
      registered_command = configurator.configure(:parrot) do |cmd|
        cmd.summary "The ultimate copy-cat."
        cmd.argument :saying, default: "SQUAWK"

        cmd.helper :yell do |saying|
          say saying.to_s.upcase
        end

        cmd.helper :woot do
          yell :woot
        end

        cmd.on_run do |options|
          yell options[:saying]
          woot
        end
      end

      expect(registered_command.summary).to eq "The ultimate copy-cat."
      expect(registered_command.description).to eq nil
      expect(registered_command.arguments.size).to eq 1
      expect(registered_command.arguments.first.name).to eq :saying
      expect(registered_command.arguments.first.default).to eq "SQUAWK"
      expect(registered_command.flags.size).to eq 0
      expect(registered_command.switches.size).to eq 0

      output = spy("output")
      registered_command.output = output

      registered_command.run [
        GitCommander::Command::Option.new(name: :saying, value: "Salutations")
      ]
      expect(output).to have_received(:puts).with "SALUTATIONS"
      expect(output).to have_received(:puts).with "WOOT"
    end

    it "rescues syntax errors and reports them in the LoaderResult" do
      expect do
        configurator.configure(:danger) do |cmd| # rubocop:disable Style/SymbolProc
          cmd.danger!
        end
      end.to raise_error described_class::ConfigurationError
    end
  end
end
