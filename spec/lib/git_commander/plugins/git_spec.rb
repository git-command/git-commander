# frozen_string_literal: true

require "spec_helper"
require "git_commander/rspec"

RSpec.describe "git plugin" do
  include GitCommander::RSpec::PluginHelpers

  let(:registry) { GitCommander::Registry.new }
  let(:loader) { GitCommander::Plugin::Loader.new(registry) }
  let(:git_plugin) { loader.load :git }
  let(:fake_rugged_config) { Class.new }
  let(:fake_rugged_repository) { spy("Rugged::Repository") }
  let(:mock_system) { class_double(GitCommander::System) }
  let(:git_commander_config_path) { "#{ENV["HOME"]}/.gitconfig.commander" }

  before do
    stub_const "Rugged::Config", fake_rugged_config
    stub_const "Rugged::Repository", fake_rugged_repository
    allow(fake_rugged_config).to receive(:new).with(git_commander_config_path)
    allow(loader).to receive(:system).and_return(mock_system)
  end

  it "installs and loads the rugged gem" do
    expect { git_plugin }.to have_defined_gems [
      "gem 'rugged'"
    ]
  end

  it "establishes a custom ~/.gitconfig.commander include for storing git-commander configurations" do
    stub_inline_gemfile
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(git_commander_config_path).and_return(false)

    expect(fake_rugged_config).to receive(:new).with(git_commander_config_path)
    expect(fake_rugged_repository).to receive(:new).with(Dir.pwd)
    expect(mock_system).to receive(:run).with "touch #{git_commander_config_path}"
    expect(mock_system).
      to receive(:say).
      with "Created #{git_commander_config_path} for git-commander specific configurations."
    expect(mock_system).to receive(:run).with "git config --global --add include.path \"#{git_commander_config_path}\""
    expect(mock_system).to receive(:say).with "Added #{git_commander_config_path} to include.path in $HOME/.gitconfig"

    git_plugin
  end

  it "returns a Rugged::Repository instance for the current directory" do
    stub_inline_gemfile
    expect(git_plugin.plugins.first.executor.source_instance).to eq fake_rugged_repository
  end

  context "when the custom ~/.gitconfig.commander file already exists" do
    it "skip creation of the custom git-config file" do
      stub_inline_gemfile
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(git_commander_config_path).and_return(true)

      expect(mock_system).to_not receive(:run).with "touch #{git_commander_config_path}"
      expect(mock_system).
        to_not receive(:say).
        with "Created #{git_commander_config_path} for git-commander specific configurations."
      expect(mock_system).
        to_not receive(:say).
        with "Added #{git_commander_config_path} to include.path in $HOME/.gitconfig"

      git_plugin
    end
  end
end
