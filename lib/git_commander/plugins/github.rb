# frozen_string_literal: true

gemfile do
  source "https://rubygems.org"
  gem "octokit"
end

plugin :prompt

command :setup do |cmd|
  cmd.summary "Connects to GitHub, creates an access token, and stores it in the git-cmd section of your git config"

  cmd.on_run do
    gh_user = prompt.ask("Please enter your GitHub username", required: true)
    gh_password = promt.mask("Please enter your GitHub password (this is NOT stored): ", required: true)

    github.login = gh_user
    github.password = gh_password

    # Check for 2-factor requirements
    begin
      client.user
    rescue Octokit::Unauthorized
      github.user(
        gh_user,
        headers: { "X-GitHub-OTP" => prompt.ask("Please enter your two-factor authentication code") }
      )
    end

    say "GitHub account successfully setup!"
  end
end

Octokit::Client.new
