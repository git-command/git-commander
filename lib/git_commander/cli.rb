# frozen_string_literal: true

require_relative "registry"
require_relative "version"
require "optparse"

module GitCommander
  # @abstract Manages command line execution within the context of GitCommander
  class CLI
    attr_reader :output, :registry

    # @param registry [GitCommander::Registry] (GitCommander::Registry.new) the
    # command registry to use for matching available commands
    # @param output [IO] (STDOUT) the IO object you want to use to send output to when running commands
    def initialize(registry: GitCommander::Registry.new, output: STDOUT)
      @registry = registry
      @output = output
    end

    # Runs a GitCommander command
    #
    # @param args [Array] (ARGV) a list of arguments to pass to the registered command
    def run(args = ARGV)
      arguments = Array(args)
      command = registry.find arguments.shift
      options = parse_command_options!(command, arguments)
      command.run options
    rescue Registry::CommandNotFound
      GitCommander.logger.error "#{command} not found in registry.  Available commands: #{registry.commands.keys.inspect}"
      help
    end

    def say(message)
      output.puts message
    end

    # Parses ARGV for the provided git-cmd command name
    #
    # @param command [Command] the git-cmd command to parse the arguments for
    # @param arguments [Array] the command line arguments
    # @return options [Array] the GitCommander::Command options with values
    def parse_command_options!(command, arguments)
      parser = configure_option_parser_for_command(command)
      parser.parse!(arguments)

      # Add arguments to options to pass to defined commands
      command.arguments.each do |argument|
        argument.value = arguments.shift
      end

      command.options
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
      command.help
      GitCommander.logger.debug "[CLI] Failed to parse command line options – #{e.inspect}"
      exit 1
    end

    private

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

    def configure_option_parser_for_command(command)
      valid_arguments_for_command = command.arguments.map { |arg| "[#{arg.name}]" }.join(" ")

      OptionParser.new do |opts|
        opts.banner = "USAGE:\n    git-cmd #{command.name} [command options] #{valid_arguments_for_command}"
        opts.separator  ""
        opts.separator  "COMMAND OPTIONS:" if command.flags.any? || command.switches.any?

        configure_flags_for_option_parser_and_command(opts, command)
        configure_switches_for_option_parser_and_command(opts, command)
      end
    end

    def configure_flags_for_option_parser_and_command(option_parser, command)
      command.flags.each do |flag|
        option_parser.on("-#{flag.name[0]}", command_line_flag_formatted_name(flag), flag.description.to_s) do |f|
          flag.value = f
        end
      end
    end

    def configure_switches_for_option_parser_and_command(option_parser, command)
      command.switches.each do |switch|
        option_parser.on("-#{switch.name[0]}", "--[no-]#{switch.name}", switch.description) do |s|
          switch.value = s
        end
      end
    end

    def command_line_flag_formatted_name(flag)
      "--#{underscore_to_kebab(flag.name)} #{flag.name.upcase}"
    end

    def underscore_to_kebab(sym_or_string)
      sym_or_string.to_s.gsub("_", "-").to_sym
    end
  end
end
