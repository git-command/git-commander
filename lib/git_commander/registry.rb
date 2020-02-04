# frozen_string_literal: true

require_relative "loaders/base_loader"
require_relative "loaders/raw"
require_relative "loaders/result"

module GitCommander
  # @abstract Manages available GitCommander commands
  class Registry
    class CommandNotFound < StandardError; end
    class LoadError < StandardError; end

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

    # Adds a pre-built command to the registry
    # @param [Command] command the Command instance to add to the registry
    def register_command(command)
      GitCommander.logger.debug "[#{logger_tag}] Registering command `#{command.name}` with args: #{command.inspect}..."

      commands[command.name] = command
    end

    # Adds command(s) to the registry using the given loader
    #
    # @param [CommandLoader] loader the class to use to load with
    def load(loader, *args)
      result = loader.new(self).load(*args)
      result.commands.each { |cmd| register_command(cmd) } if result.success?

      result
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
