# frozen_string_literal: true

require_relative "registry"
require_relative "version"
require "optparse"

module GitCommander
  # @abstract Manages command line execution within the context of GitCommander
  class CLI
    attr_reader :output, :registry

    def initialize(registry: GitCommander::Registry.new, output: STDOUT)
      @registry = registry
      @output = output
    end

    # Runs a GitCommander command
    def run(args = ARGV)
      arguments = Array(args)
      command = registry.find arguments.shift
      options = parse_command_options!(command, arguments)
      command.run options
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
      say "    git-cmd command [command options] [arguments...]"
      say "COMMANDS"
      say registry.commands.keys.join(", ")
    end

    def say(message)
      output.puts message
    end

    # Parses ARGV for the provided git-cmd command name
    #
    # @param command [Command] the git-cmd command to parse the arguments for
    # @param arguments [Array] the command line arguments
    def parse_command_options!(command, arguments)
      options = {}
      valid_arguments_for_command = command.arguments.map { |arg| "[#{arg.name}]" }.join(" ")

      parser = OptionParser.new do |opts|
        opts.banner = "USAGE:\n    git-cmd #{command.name} [command options] #{valid_arguments_for_command}"
        opts.separator  ""
        opts.separator  "COMMAND OPTIONS:" if command.flags.any? || command.switches.any?

        command.flags.each do |flag|
          opts.on("-#{flag.name[0]}", "--#{underscore_to_kebab(flag.name)} #{flag.name.upcase}", flag.description.to_s) do |f|
            options[flag.name] = f || flag.default
          end
        end

        command.switches.each do |switch|
          opts.on("-#{switch.name[0]}", "--[no-]#{switch.name}", switch.description) do |s|
            options[switch.name] = s || switch.default
          end
        end
      end
      parser.parse!(arguments)

      # Add arguments to options to pass to defined commands
      command.arguments.each do |argument|
        options[argument.name] = arguments.shift || argument.default
      end
      # Add any defaults
      (command.flags + command.switches).each do |option|
        options[option.name] ||= option.default
      end

      options
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
      command.help
      GitCommander.logger.debug "[CLI] Failed to parse command line options – #{e.inspect}"
      exit 1
    end

    private

    def underscore_to_kebab(sym_or_string)
      sym_or_string.to_s.gsub("_", "-").to_sym
    end
  end
end
