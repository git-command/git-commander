# frozen_string_literal: true

require "English"

module GitCommander
  # @abstract A wrapper for system calls
  class System
    DEFAULT_RUN_OPTIONS = {
      silent: false,
      with_system: false
    }.freeze

    class RunError < StandardError; end

    # Runs a system command
    # @param [String] command the command string (with args, flags and switches) to run
    # @param [Hash] options the options to run the command with
    # @option options [Boolean] :silent Supress the output of the command
    # @option options [Boolean] :with_system Execute command in a subshell using `system`
    def run(command, options = {})
      options = DEFAULT_RUN_OPTIONS.merge(options)

      GitReflow.logger.debug "[system] Running #{command} with options #{options.inspect} ..."

      return system(command) if options[:with_system] == true

      # Disable CommandLiteral rubocop in this case since we want to allow
      # backticks in the command string
      output = %x(#{command}) # rubocop:disable Style/CommandLiteral

      raise RunError.new(output, "\"#{command}\" failed to run.") unless $CHILD_STATUS.success?

      puts output if options[:silent] == false
      output
    end
  end
end
