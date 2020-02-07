# frozen_string_literal: true

gemfile do
  source "https://rubygems.org"
  gem "git"
end

Git.open Dir.pwd, log: GitCommander.logger
