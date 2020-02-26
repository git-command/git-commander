# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Run plugin command" do
  before :all do
    setup_environment
  end

  after :all do
    command_helpers_teardown
  end

  describe "current command" do
    before do
      setup_working_branch "feature-branch"
      make_commit "Updated README"
      copy_file_to_project(
        "#{fixtures_dir}/plugins/git_helpers.rb",
        "#{project_dir}/.git-commands/plugins/git_helpers.rb"
      )
    end

    it "outputs the current changes" do
      run_system_call "#{git_cmd_path} git-helpers:current"
      expect(last_command.output).
        to include("Updated README")
    end
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
