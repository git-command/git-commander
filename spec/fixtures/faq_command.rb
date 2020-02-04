# frozen_string_literal: true

command :faq do |cmd|
  cmd.summary "Outputs a question and answer combination."
  cmd.description "This is way too much information about a simple FAQ section."
  cmd.argument :question
  cmd.argument :answer, default: "Because racecar."
  cmd.flag :with_question, default: false
  cmd.switch :loud, default: false

  cmd.on_run do |options|
    say "Question: #{options[:question]}?" if options[:with_question]
    response = options[:loud] ? options[:answer].upcase : options[:answer]
    say "Answer: #{response}"
  end
end
