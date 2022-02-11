# frozen_string_literal: true

require_relative "plugin/executor"

module GitCommander
  #
  # @abstract Allows for proxying methods to a plugin from within the context of
  # a Command's block.
  #
  # A Plugin provides additional external instances to a Command's @block
  # context.  Plugins can define their own inline gems, and can define
  # additional Commands.
  #
  # @example A simple `git` plugin
  #   require "git"
  #   git_instance = Git.open(Dir.pwd, log: GitCommander.logger)
  #   GitCommander::Plugin.new(:git, source_instance: git_instance)
  #
  class Plugin
    class CommandNotFound < StandardError; end

    attr_accessor :commands, :executor, :name, :registry

    # Creates a Plugin object. +name+ is the name of the plugin.
    #
    # Options include:
    #
    # +source_instance+ - an instance of an object to use in the Command's block context
    # +registry+ - a Registry instance for where this Plugin will be stored for lookup
    def initialize(name, source_instance: nil, registry: nil)
      @name = name
      @executor = Executor.new(source_instance) if source_instance
      @registry = registry || GitCommander::Registry.new
    end

    def find_command(command_name)
      GitCommander.logger.debug "[#{logger_tag}] looking up command: #{command_name.inspect}"
      command = commands[command_name.to_s.to_sym]
      raise CommandNotFound, "[#{logger_tag}] #{command_name} does not exist for this plugin" if command.nil?

      command
    end

    private

    def logger_tag
      [name, "plugin"].compact.join(" ")
    end
  end
end
