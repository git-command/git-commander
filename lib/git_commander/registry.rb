# frozen_string_literal: true

module GitCommander
  # @abstract Manages available GitCommander commands
  class Registry
    class CommandNotFound < StandardError; end

    attr_accessor :commands, :name

    def initialize
      @commands = {}
    end

    # Adds a command to the registry
    #
    # @param [String, Symbol] command_name the name of the command to add to the
    #   registry
    def register(command_name, **options, &block)
      command_name = command_name.to_sym

      GitCommander.logger.debug "[#{logger_tag}] Registering command `#{command_name}` with args: #{options.inspect}..."
      commands[command_name] = GitCommander::Command.new(command_name, registry: self, **options.merge(block: block))
    end

    # Looks up a command in the registry
    #
    # @param [String, Symbol] command_name the name of the command to look up in the
    #   registry
    #
    # @example Fetch a command from the registry
    #   registry = GitCommander::Registry.new
    #   registry.register :wtf
    #   registry.find :wtf
    #
    # @raise [CommandNotFound] when no command is found in the registry
    # @return [GitCommander::Command, #run] a command object that responds to #run
    def find(command_name)
      GitCommander.logger.debug "[#{logger_tag}] looking up command: #{command_name.inspect}"
      command = commands[command_name.to_s.to_sym]
      raise CommandNotFound, "[#{logger_tag}] #{command_name} does not exist in the registry" if command.nil?

      command
    end

    private

    def logger_tag
      [name, "registry"].compact.join(" ")
    end
  end
end
