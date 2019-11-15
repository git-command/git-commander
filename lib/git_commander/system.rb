# frozen_string_literal: true

require "singleton"
require "open3"

module GitCommander
  # @abstract A wrapper for system calls
  class System
    DEFAULT_RUN_OPTIONS = {
      silent: false,
    }.freeze

    class Command
      attr_accessor :output, :error, :status
      attr_reader :name, :arguments, :options, :command_with_arguments
      def initialize(command_with_arguments, options = {})
        @command_with_arguments = command_with_arguments
        @arguments = command_with_arguments.to_s.split(" ").reject { |p| p.empty? }
        @name = @arguments.shift
        @options = DEFAULT_RUN_OPTIONS.merge(options)
      end

      def run
        log_command_initiated
        @output, @error, @status = Open3.capture3(name, *arguments)
        log_command_completed
      end

      private

      def log_command_initiated
        GitCommander.logger.debug <<~COMMAND_LOG
          [system] Running #{name} with arguments #{arguments.inspect} and options #{options.inspect} ...
          COMMAND_LOG
      end

      def log_command_completed
        GitCommander.logger.debug <<~COMMAND_LOG
          [system] Ran #{name} with arguments #{arguments.inspect} and options #{options.inspect}.
          \tStatus: #{status}
          \tOutput: #{output.inspect}
          \tError: #{error.inspect}
          COMMAND_LOG
      end
    end

    class RunError < StandardError; end

    include Singleton

    # Runs a system command
    # @param [String] command the command string (with args, flags and switches) to run
    # @param [Hash] options the options to run the command with
    # @option options [Boolean] :silent Supress the output of the command
    # @option options [Boolean] :blocking Supress errors running the command
    def self.run(command_with_arguments, options = {})
      command = Command.new(command_with_arguments, options)

      command.run

      if !command.status.success?
        raise RunError, "\"#{command.error}\" \"#{command.name}\" failed to run." unless command.options[:blocking] == false
      end

      puts command.output if command.options[:silent] == false
      command.output
    end
  end
end
