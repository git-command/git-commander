# frozen_string_literal: true

gemfile do
  source "https://rubygems.org"
  gem "rugged"
end

CONFIG_FILE_PATH = "#{ENV["HOME"]}/.gitconfig.commander"

# @private
# Overrides Rugged::Repository#global_config so that we can use a custom config
# file for all git-commander related configurations
class RuggedRepositoryWithCustomConfig < SimpleDelegator
  attr_reader :global_config

  def initialize(repository)
    @global_config = Rugged::Config.new(CONFIG_FILE_PATH)
    super repository
  end
end

unless File.exist?(CONFIG_FILE_PATH)
  system.run "touch #{CONFIG_FILE_PATH}"
  system.say "Created #{CONFIG_FILE_PATH} for git-commander specific configurations."
  system.run "git config --global --add include.path \"#{CONFIG_FILE_PATH}\""
  system.say "Added #{CONFIG_FILE_PATH} to include.path in $HOME/.gitconfig"
end

RuggedRepositoryWithCustomConfig.new(
  Rugged::Repository.new(Dir.pwd)
)
