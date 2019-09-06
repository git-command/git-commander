# frozen_string_literal: true

require "git_commander/command"
require "git_commander/logger"
require "git_commander/registry"
require "git_commander/version"

# GitCommander is the global module used to house the global logger
module GitCommander
  module_function

  def logger(*args)
    @logger ||= GitCommander::Logger.new(*args)
  end
end
