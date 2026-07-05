# frozen_string_literal: true

gemfile do
  source "https://rubygems.org"
  gem "octokit"
end

plugin :git
plugin :prompt

command :setup do |cmd|
  cmd.summary "Connects to GitHub using a personal access token and verifies the credentials"

  cmd.on_run do
    gh_token = prompt.mask(
      "Please enter a GitHub personal access token (https://github.com/settings/tokens): ",
      required: true
    )

    github.access_token = gh_token

    begin
      say "GitHub account @#{github.user.login} successfully setup!"
    rescue Octokit::Unauthorized
      say "GitHub could not authenticate with the provided token. Please check the token and try again."
    end
  end
end

Octokit::Client.new
