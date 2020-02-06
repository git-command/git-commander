# frozen_string_literal: true

command :hello do |cmd|
  cmd.on_run do |_options|
    say "Hello."
  end
end
