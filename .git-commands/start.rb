plugin :github

command :start do |cmd|
  cmd.summary "Start work on a git-commander issue"

  cmd.helper :github_setup? do
    !git.config["github.site"].to_s.strip.emtpy? &&
      !git.config["github.api"].to_s.strip.emtpy? &&
      !git.config["github.login"].to_s.strip.emtpy? &&
      !git.config["github.token"].to_s.strip.emtpy?
  end

  cmd.on_run do |cmd|
    run "github:setup", [GitCommander::Command::Option.new(name: :silence_success, value: true)] unless github_setup?
    say "Woot"
  end
end
