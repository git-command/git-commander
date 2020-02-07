# frozen_string_literal: true

require_relative "loader"
require_relative "plugin/loader"
require_relative "command/loaders/file_loader"
require_relative "command/loaders/raw"

module GitCommander
  # @abstract Manages available GitCommander commands
  class Registry
    class CommandNotFound < StandardError; end
    class LoadError < StandardError; end

    attr_accessor :commands, :name, :plugins

    def initialize
      @commands = {}
      @plugins = {}
    end

    # Adds a command to the registry
    #
    # @param [String, Symbol] command_name the name of the command to add to the
    #   registry
    def register(command_name, **options, &block)
      command = GitCommander::Command.new(command_name.to_sym, registry: self, **options.merge(block: block))
      register_command(command)
    end

    # Adds a pre-built command to the registry
    # @param [Command] command the Command instance to add to the registry
    def register_command(command)
      GitCommander.logger.debug "[#{logger_tag}] Registering command `#{command.name}` with args: #{command.inspect}..."

      commands[command.name] = command
    end

    # Adds a pre-built Plugin to the registry
    # @param [Plugin] plugin the Plugin instance to add to the registry
    def register_plugin(plugin)
      GitCommander.logger.debug "[#{logger_tag}] Registering plugin `#{plugin.name}`..."

      plugins[plugin.name] = plugin
    end

    # Adds command(s) to the registry using the given loader
    #
    # @param [CommandLoader] loader the class to use to load with
    def load(loader, *args)
      result = loader.new(self).load(*args)

      if result.success?
        result.plugins.each { |plugin| register_plugin(plugin) }
        result.commands.each { |cmd| register_command(cmd) }
      end

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
