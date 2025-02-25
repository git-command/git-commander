# frozen_string_literal: true

gem "octokit", ">= 4.0"

plugin(:git)
plugin(:prompt)

command :setup do |cmd|
  cmd.summary "Connects to GitHub, creates an access token, and stores it in the git-cmd section of your git config"

  cmd.on_run do
    # First check for existing
    github_token = git.config.get("git-commander.github.token")

    if github_token
      # Make sure it's still valid
      github.access_token = github_token
      begin
        github.user
        prompt.ok "GitHub account #{github.login} already setup!"
        abort
      rescue Octokit::Unauthorized => e
        # We don't care
      end
    end

    gh_user = prompt.ask("Please enter your GitHub username", required: true)
    gh_password = prompt.mask("Please enter your GitHub password (this is NOT stored): ", required: true)

    github.login = gh_user
    github.password = gh_password
    extra_client_options = {}

    # Check for 2-factor requirements
    begin
      github.user
    rescue Octokit::OneTimePasswordRequired
      extra_client_options[:headers] = { "X-GitHub-OTP" => prompt.ask("Please enter your two-factor authentication code") }
      github.user(
        gh_user,
        **extra_client_options
      )
    end

    hostname = system.run("hostname").strip
    authorization = github.authorizations(extra_client_options).select do |auth|
      auth.note == "git-commander (#{hostname})"
    end.last

    if authorization
      prompt.say "You have previously setup git-commander on this machine, but we can no longer find the stored token."
      prompt.notice "Please visit https://github.com/settings/tokens and delete the token for: git-commander (#{hostname})"
      prompt.error "Setup could not be completed."
    else
      authorization = github.create_authorization(
        scopes: ['repo'],
        note: "git-commander (#{hostname})",
        **extra_client_options
      )
    end

    github.access_token = authorization.token
    git.global_config.add("git-commander.github.token", authorization.token)

    prompt.ok "GitHub account successfully setup!"
  rescue StandardError => e
    logger.debug "[github plugin] Unexpected error: #{e.message}\n\t#{e.backtrace}"
    prompt.say "We were unable to authenticate with Github:"
    prompt.error e.message
  end
end

Octokit::Client.new access_token: `git config "git-commander.github.token"`
