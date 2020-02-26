# frozen_string_literal: true

plugin :system

command :current do |cmd|
  cmd.summary "Outputs all commits not on the base branch"
  cmd.argument :base_branch, default: "master"

  cmd.on_run do |options|
    current_branch = system.run "git rev-parse --abbrev-ref HEAD"
    system.run "git log #{options[:base_branch]}..#{current_branch} --format=\"%C(auto)%h %s %C(#999999)%ar\" --color"
  end
end
