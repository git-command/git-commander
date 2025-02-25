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

    attr_accessor :commands, :name, :plugins, :errors

    def initialize
      @commands = {}
      @plugins = {}
      @errors = { commands: {}, plugins: {} }
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
      GitCommander.logger.debug <<~DEBUG_STRING
        [#{logger_tag}] Registering command `#{command.name}` with:
        \tDescription: #{command.description || command.summary}
        \tArguments: #{command.arguments.inspect}
        \tFlags: #{command.flags.inspect}
        \tSwitches: #{command.switches.inspect}
      DEBUG_STRING

      commands[command.name] = command
    end

    # Adds a pre-built Plugin to the registry
    # @param [Plugin] plugin the Plugin instance to add to the registry
    def register_plugin(plugin)
      return unless plugins[plugin.name].nil?

      GitCommander.logger.debug "[#{logger_tag}] Registering plugin `#{plugin.name}`..."

      plugins[plugin.name] = plugin

      plugin.commands.each do |plugin_command|
        commands[plugin_command.name.to_sym] = plugin_command
      end

      plugin
    end

    # Adds command(s) or plugin(s) to the registry using the given loader
    #
    # @param [GitCommander::Loader] loader the class to use to load with
    def load(loader, *args)
      result = loader.new(self).load(*args)

      raise LoadError, "Unable to load: #{args.inspect}\n\tErrors: #{errors.inspect}" unless valid?

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

    def find_plugin(plugin_name)
      GitCommander.logger.debug "[#{logger_tag}] looking up plugin: #{plugin_name.inspect}"
      plugins[plugin_name.to_s.to_sym]
    end

    # Merges two registries
    #
    # @param [Registry] other_registry the name of another registry to merge into this one
    # @return GitCommander::Registry] the original registry with updated commands and plugins
    def merge(other_registry)
      GitCommander.logger.debug "[#{logger_tag}] merging registry commands #{other_registry.commands.keys} into #{commands.keys}"
      commands.merge!(other_registry.commands)
      GitCommander.logger.debug "[#{logger_tag}] merging registry plugins #{other_registry.plugins.keys} into #{plugins.keys}"
      plugins.merge!(other_registry.plugins)

      self
    end

    # Check the health of loaded commands and plugins
    #
    # @return [Boolean] false when any command or plugin had an issue registering
    def valid?
      errors[:commands].empty? && errors[:plugins].empty?
    end

    private

    def logger_tag
      [name, "registry"].compact.join(" ")
    end
  end
end
