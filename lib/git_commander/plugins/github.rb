# frozen_string_literal: true

gemfile do
  source "https://rubygems.org"
  gem "octokit"
end

plugin :git
plugin :prompt

command :setup do |cmd|
  cmd.summary "Connects to GitHub, creates an access token, and stores it in the git-cmd section of your git config"
  cmd.flag :silence_success, default: false, description: "Silence output when already setup"

  cmd.helper :github_setup? do
    !git.config["github.site"].to_s.strip.emtpy? &&
      !git.config["github.api"].to_s.strip.emtpy? &&
      !git.config["github.login"].to_s.strip.emtpy? &&
      !git.config["github.token"].to_s.strip.emtpy?
  end

  cmd.on_run do |options|
    if github_setup?
      return if options[:silence_success]

      say <<~ALREADY_SETUP
        GitHub already setup:
        \tsite:  #{git.config["github.site"]}
        \tapi:   #{git.config["github.api"]}
        \tlogin: #{git.config["github.login"]}
      ALREADY_SETUP
    end

    gh_user = prompt.ask("Please enter your GitHub username", required: true)

    say "Visit https://github.com/settings/tokens if you don't already have an access token."
    gh_token = prompt.mask("Enter your token: ", required: true)

    github.login = gh_user
    github.access_token = gh_token

    begin
      github.user
    rescue Octokit::Unauthorized => e
      fail "Unable to authenticate your GitHub credentials: #{e}"
    end

    say "GitHub account successfully setup!"
  end
end

Octokit::Client.new
