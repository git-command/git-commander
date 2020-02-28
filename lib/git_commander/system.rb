# frozen_string_literal: true

require "singleton"
require "open3"

module GitCommander
  # @abstract A wrapper for system calls
  class System
    DEFAULT_RUN_OPTIONS = {
      silent: false
    }.freeze

    # @abstract Wraps a system command with logging, stderr, and stdout capture
    class Command
      attr_accessor :output, :error, :status
      attr_reader :name, :options, :command_with_arguments
      def initialize(command_with_arguments, options = {})
        @command_with_arguments = command_with_arguments
        @name = command_with_arguments.split(/\w/i).first
        @options = DEFAULT_RUN_OPTIONS.merge(options)
      end

      def run
        log_command_initiated
        @output, @error, @status = Open3.capture3(command_with_arguments)
        log_command_completed
      end

      private

      def log_command_initiated
        GitCommander.logger.debug <<~COMMAND_LOG
          [system] Running '#{command_with_arguments}' with options #{options.inspect} ...
        COMMAND_LOG
      end

      def log_command_completed
        GitCommander.logger.debug <<~COMMAND_LOG
          [system] Ran '#{command_with_arguments}' with options #{options.inspect}.
          \tStatus: #{status}
          \tOutput: #{output.inspect}
          \tError: #{error.inspect}
        COMMAND_LOG
      end
    end

    class RunError < StandardError; end

    include Singleton

    # Runs a system command
    # @param [String] command_with_arguments the command string (with args, flags and switches) to run
    # @param [Hash] options the options to run the command with
    # @option options [Boolean] :silent Supress the output of the command
    # @option options [Boolean] :blocking Supress errors running the command
    def self.run(command_with_arguments, options = {})
      command = Command.new(command_with_arguments, options)

      command.run

      unless command.status.success? || command.options[:blocking] == false
        raise RunError, "\"#{command.error}\" \"#{command.name}\" failed to run."
      end

      puts command.output if command.options[:silent] == false
      command.output.strip
    end
  end
end
