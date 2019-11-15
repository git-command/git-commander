# frozen_string_literal: true

require "rubygems"
require "rspec"
require "singleton"

$LOAD_PATH << "lib"
require "git_commander"

require_relative "support/command_helpers"

RSpec.configure do |config|
  config.include CommandHelpers

  config.expect_with :rspec do |c|
    c.syntax = %i[should expect]
  end

  config.mock_with :rspec do |c|
    c.syntax = %i[should expect]
  end
end
