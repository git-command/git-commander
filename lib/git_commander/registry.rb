# frozen_string_literal: true

module GitCommander
  # @abstract Manages available GitCommander commands
  class Registry
    class CommandNotFound < StandardError; end

    attr_accessor :commands

    def initialize
      @commands = {}
    end

    # Adds a command to the registry
    #
    # @param [String, Symbol] name the name of the command to add to the
    #   registry
    def register(name, **options, &block)
      command_name = name.to_sym

      GitCommander.logger.debug "[registry] Registering command `#{command_name}` with args: #{options.inspect}..."
      commands[command_name] = GitCommander::Command.new(command_name, **options.merge(block: block))
    end

    # Looks up a command in the registry
    #
    # @param [String, Symbol] name the name of the command to look up in the
    #   registry
    #
    # @example Fetch a command from the registry
    #   registry = GitCommander::Registry.new
    #   registry.register :wtf
    #   registry.find :wtf
    #
    # @raise [CommandNotFound] when no command is found in the registry
    # @return [GitCommander::Command, #run] a command object that responds to #run
    def find(name)
      GitCommander.logger.debug "[registry] looking up command: #{name.inspect}"
      command = commands[name.to_s.to_sym]
      raise CommandNotFound, "#{name} does not exist in the registry" if command.nil?

      command
    end
  end
end
