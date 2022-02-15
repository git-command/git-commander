# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Run command with arguments" do
  before :all do
    setup_environment
  end

  after :all do
    command_helpers_teardown
  end

  describe "command help" do
    before do
      # Ensure we don't have lingering commands in our test project
      FileUtils.rm_rf "#{project_dir}/Workflow"
      FileUtils.rm_rf "#{project_dir}/.git-commands"
    end

    it "displays help text for commands registered in Workflow file" do
      FileUtils.cp "#{fixtures_dir}/workflow_example.rb", "#{project_dir}/Workflow"

      run_system_call "#{git_cmd_path} help"
      expect(last_command.output).
        to include("hello, faq")

      run_system_call "#{git_cmd_path} faq --help"
      expect(last_command.output).
        to include("git-cmd faq [command options] [question] [answer]")
      expect(last_command.output).to include("-w WITH_QUESTION")
      expect(last_command.output).to include("--with-question")
      expect(last_command.output).to include("-l, --[no-]loud")
    end

    it "displays help text for commands registered in .git-commands directory" do
      FileUtils.mkdir "#{project_dir}/.git-commands"
      FileUtils.cp "#{fixtures_dir}/faq_command.rb", "#{project_dir}/.git-commands/faq.rb"
      FileUtils.cp "#{fixtures_dir}/hello_command.rb", "#{project_dir}/.git-commands/hello.rb"

      run_system_call "#{git_cmd_path} help"
      expect(last_command.output).to include("faq")
      expect(last_command.output).to include("hello")

      run_system_call "#{git_cmd_path} faq --help"
      expect(last_command.output).
        to include("git-cmd faq [command options] [question] [answer]")
      expect(last_command.output).to include("-w WITH_QUESTION")
      expect(last_command.output).to include("--with-question")
      expect(last_command.output).to include("-l, --[no-]loud")
    end

    it "ignores loading commands from .git-commands directory if it doesn't exist" do
      FileUtils.rm_rf "#{project_dir}/Workflow"
      FileUtils.rm_rf "#{project_dir}/.git-commands"
      run_system_call "#{git_cmd_path} help"

      expect(last_command.output).to_not include("faq")
      expect(last_command.output).to_not include("hello")
    end
  end
end
