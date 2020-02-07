# frozen_string_literal: true

gemfile do
  source "https://rubygems.org"
  gem "git"
  gem "rspec" # This is a stop-gap to allow testing of these in the context of the gem
end

Git.open Dir.pwd, log: GitCommander.logger
