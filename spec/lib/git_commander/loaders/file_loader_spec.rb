# frozen_string_literal: true

require "spec_helper"

RSpec.describe GitCommander::Loaders::FileLoader do
  let(:registry) { GitCommander::Registry.new }
  let(:loader) { described_class.new(registry) }

  describe ".load(filename)" do
    it "loads the commands defined in the provided filename" do
      loader.load File.expand_path("spec/fixtures/workflow_example.rb")

      expect(loader.result).to be_success
      expect(loader.result.commands.size).to eq 2

      expect(loader.result.commands.first.name).to eq :hello

      registered_command = loader.result.commands.last
      expect(registered_command.summary).to eq "Outputs a question and answer combination."
      expect(registered_command.description).to eq "This is way too much information about a simple FAQ section."
      expect(registered_command.arguments.size).to eq 2
      expect(registered_command.arguments.first.name).to eq :question
      expect(registered_command.arguments.last.name).to eq :answer
      expect(registered_command.arguments.last.default).to eq "Because racecar."
      expect(registered_command.flags.size).to eq 1
      expect(registered_command.flags.first.name).to eq :with_question
      expect(registered_command.flags.first.default).to eq false
      expect(registered_command.switches.size).to eq 1
      expect(registered_command.switches.first.name).to eq :loud
      expect(registered_command.switches.first.default).to eq false

      output = spy("output")
      registered_command.output = output

      question = "Can I kick it"
      answer = "Yes you can!"
      expect(output).to receive(:puts).once.with("Question: #{question}?").ordered
      expect(output).to receive(:puts).once.with("Answer: #{answer.upcase}").ordered
      registered_command.run [
        GitCommander::Command::Option.new(name: :question, value: question),
        GitCommander::Command::Option.new(name: :answer, value: answer),
        GitCommander::Command::Option.new(name: :with_question, value: true),
        GitCommander::Command::Option.new(name: :loud, value: true)
      ]
    end

    it "reports FileLoader::FileNotFound if the file does not exist" do
      result = loader.load "bubbles"

      expect(result).to_not be_success

      resulting_error = result.errors.first
      expect(resulting_error).to be_kind_of described_class::FileNotFoundError
      expect(resulting_error.message).to include "No such file or directory"
      expect(resulting_error.backtrace).to_not be_empty
    end

    it "reports FileLoader::LoadError if it has a problem reading the file" do
      allow(File).to receive(:read).and_raise Errno::EACCES
      result = loader.load File.expand_path("spec/fixtures/workflow_example.rb")

      expect(result).to_not be_success

      resulting_error = result.errors.first
      expect(resulting_error).to be_kind_of described_class::FileLoadError
      expect(resulting_error.message).to include "Permission denied"
      expect(resulting_error.backtrace).to_not be_empty
    end

    it "raises a CommandFileLoader::LoadError if there's a problem evaluating the file" do
      allow(File).to receive(:read).and_return(
        <<~COMMANDS
          command :hello d |cmd = nil|
            cmd.danger!
          end
        COMMANDS
      )

      result = loader.load File.expand_path("spec/fixtures/workflow_example.rb")

      expect(result).to_not be_success

      resulting_error = result.errors.first
      expect(resulting_error).to be_kind_of GitCommander::Loaders::Raw::CommandParseError
      expect(resulting_error.message).to include "syntax error"
      expect(resulting_error.backtrace).to_not be_empty
    end
  end
end
