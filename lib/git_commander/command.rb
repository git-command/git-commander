# frozen_string_literal: true

require "set"
require_relative "command/configurator"
require_relative "command/option"
require_relative "command/runner"
require_relative "command_loader_options"

module GitCommander
  # @abstract Wraps domain logic for executing git-cmd commands
  class Command
    include GitCommander::CommandLoaderOptions

    attr_reader :arguments, :flags, :switches, :block, :name, :registry
    attr_accessor :output

    # @param name [String, Symbol] the name of the command
    # @param registry [GitCommander::Registry] (GitCommander::Registry.new) the
    # command registry to use lookups
    # @param options [Hash] the options to create the command with
    # @option options [String] :description (nil) a short description to use in the
    # single line version of the command's help output
    # @option options [String] :summary (nil) the long-form description of the command
    # to use in the command's help output
    # @option options [IO] :output (STDOUT) the IO object you want to use to
    # send outut from the command to
    # @option options [Array] :arguments an array of hashes describing the
    # argument names and default values that can be supplied to the command
    # @option options [Array] :flags an array of hashes describing the
    # flags and default values that can be supplied to the command
    # @option options [Array] :switches an array of hashes describing the
    # switches and default values that can be supplied to the command
    def initialize(name, registry: nil, **options, &block)
      @name = name
      @description = options[:description]
      @summary = options[:summary]
      @block = block_given? ? block : proc {}
      @registry = registry || GitCommander::Registry.new
      @output = options[:output] || STDOUT

      define_command_options(options)
    end

    # Executes the block for the command with the provided run_options.
    #
    # @param run_options
    def run(run_options = [])
      assign_option_values(run_options)
      Runner.new(self).run options.map(&:to_h).reduce(:merge)
    end

    def say(message)
      output.puts message
    end

    def help
      say "NAME"
      say "    git-cmd #{name} – #{summary}"
      say "USAGE"
      say "    git-cmd #{name} [command options] #{arguments.map { |arg| "[#{arg.name}]" }.join(" ")}"
      description_help
      argument_help
      options_help
    end

    def options
      Set.new(@arguments + @flags + @switches)
    end

    def add_option(option_type, options = {})
      case option_type.to_sym
      when :argument
        @arguments << Option.new(**options)
      when :flag
        @flags << Option.new(**options)
      when :switch
        @switches << Option.new(**options)
      end
    end

    private

    def define_command_options(options)
      @arguments = options_from_hash(options[:arguments])
      @flags = options_from_hash(options[:flags])
      @switches = options_from_hash(options[:switches])
    end

    def options_from_hash(hash)
      Array(hash).map { |v| Option.new(**v) }
    end

    def assign_option_values(command_options)
      options.each do |option|
        command_option = command_options.find { |o| o.name == option.name }
        next if command_option.nil?

        option.value = command_option.value
      end
    end

    def description_help
      return if description.to_s.empty?

      say "DESCRIPTION"
      say "    #{description}"
    end

    def argument_help
      return unless arguments.any?

      say "ARGUMENTS"
      arguments.each do |argument|
        default_text = argument.default.nil? ? "" : "(default: #{argument.default.inspect}) "
        say "    #{argument.name} – #{default_text}#{argument.description}"
      end
    end

    def options_help
      return unless flags.any? || switches.any?

      say "COMMAND OPTIONS"
      flag_help
      switch_help
    end

    def flag_help
      flags.each do |flag|
        flag_names = ["-#{flag.name.to_s[0]}", "--#{flag.name}"]
        say "    #{flag_names} – #{flag.default.nil? ? "" : "(default: #{flag.default})  "}#{flag.description}"
      end
    end

    def switch_help
      switches.each do |switch|
        switch_names = [switch.name.to_s[0], "-#{switch.name}"].map { |s| "-#{s}" }.join(", ")
        say "    #{switch_names} – #{switch.default.nil? ? "" : "(default: #{switch.default})  "}#{switch.description}"
      end
    end
  end
end
