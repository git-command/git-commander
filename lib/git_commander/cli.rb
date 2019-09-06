# frozen_string_literal: true

require_relative "registry"
require_relative "version"

module GitCommander
  # @abstract Manages command line execution within the context of GitCommander
  class CLI
    attr_accessor :output, :registry

    def initialize(registry: GitCommander::Registry.new, output: STDOUT)
      @registry = registry
      @output = output
    end

    # Runs a GitCommander command
    def run(args = ARGV)
      command = registry.find Array(args).shift
      command.run
    rescue Registry::CommandNotFound
      GitCommander.logger.error "#{command} not found in registry.  Available commands: #{registry.commands.keys.inspect}"
      help
    end

    def help
      say "NAME"
      say "    git-cmd – Git Commander allows running custom git commands from a centralized location."
      say "VERSION"
      say "    #{GitCommander::VERSION}"
      say "USAGE"
      say "    git-reflow command [command options] [arguments...]"
      say "COMMANDS"
    end

    def say(message)
      output.puts message
    end
  end
end
