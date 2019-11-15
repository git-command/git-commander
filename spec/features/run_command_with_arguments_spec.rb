# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Run command with arguments" do
  before :all do
    setup_environment
  end

  after :all do
    command_helpers_teardown
  end

  describe "help command" do
    it "outputs the name, description, version number and usage for the git-cmd command" do
      run_system_call "#{git_cmd_path} help"
      expect(last_command.output).
        to include("git-cmd – Git Commander allows running custom git commands from a centralized location")
      expect(last_command.output).
        to include(GitCommander::VERSION)
      expect(last_command.output).
        to include("git-cmd command [command options] [arguments...]")
    end
  end
end
