# frozen_string_literal: true

require "logger"

module GitCommander
  # Handles logging for GitCommander
  class Logger < ::Logger
    DEFAULT_LOG_FILE = "/tmp/git-commander.log"

    def initialize(*args)
      log_file = args.shift || log_file_path
      args.unshift(log_file)
      super(*args)
      @formatter = SimpleFormatter.new
    end

    # Simple formatter which only displays the message.
    class SimpleFormatter < ::Logger::Formatter
      # This method is invoked when a log event occurs
      def call(severity, _timestamp, _progname, msg)
        "#{severity}: #{String === msg ? msg : msg.inspect}\n"
      end
    end

    private

    def log_file_path
      return @log_file_path unless @log_file_path.to_s.empty?

      # Here we have to run the command in isolation to avoid a recursive loop
      # to log this command run to fetch the config setting.
      configured_log_file_path = `git config --get commander.log-file-path`

      return @log_file_path = DEFAULT_LOG_FILE if configured_log_file_path.empty?

      @log_file_path = configured_log_file_path
    end
  end
end
