# frozen_string_literal: true

require "spec_helper"
require "git_commander/rspec"

RSpec.describe "github plugin" do
  include GitCommander::RSpec::PluginHelpers

  let(:registry) { GitCommander::Registry.new }
  let(:loader) { GitCommander::Plugin::Loader }
  let(:github_plugin) { registry.load loader, :github }
  let(:fake_rugged_config) { Class.new }
  let(:fake_rugged_repository) { spy("Rugged::Repository") }
  let(:fake_github_client) { spy("Octokit::Client") }
  let(:fake_prompt) { spy("TTY::Prompt") }
  let(:mock_system) { class_double(GitCommander::System) }
  let(:git_commander_config_path) { "#{ENV["HOME"]}/.gitconfig.commander" }

  before do
    stub_const "Rugged::Config", fake_rugged_config
    stub_const "Rugged::Repository", fake_rugged_repository
    stub_const "Octokit::Client", fake_github_client
    stub_const "TTY::Prompt", fake_prompt
    allow(fake_rugged_config).to receive(:new).with(git_commander_config_path)
  end

  it "installs and loads all required dependencies" do
    expect { github_plugin }.to have_defined_gems [
      "gem 'rugged'",
      "gem 'octokit'",
      "gem 'tty-prompt'"
    ]
  end

  it "includes the git plugin" do
    stub_inline_gemfile
    github_plugin
    expect(registry.plugins.keys).to contain_exactly(:git, :github, :prompt)
  end

  it "returns a Octokit::Client instance" do
    stub_inline_gemfile
    github_plugin
    expect(registry.find_plugin(:github).executor.source_instance).to eq fake_github_client
  end
end
