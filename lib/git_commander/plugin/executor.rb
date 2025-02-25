# frozen_string_literal: true

require "delegate"

module GitCommander
  class Plugin
    # Manages the execution context for the plugin's top-level accessor in the
    # context of a command's on_run block.
    class Executor < SimpleDelegator
    end
  end
end
