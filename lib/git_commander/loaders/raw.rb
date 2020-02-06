# frozen_string_literal: true

require_relative "base_loader"

module GitCommander
  module Loaders
    # @abstract Handles loading commands from raw strings
    class Raw < BaseLoader
      class CommandParseError < StandardError; end
      class CommandConfigurationError < StandardError; end

      attr_reader :content

      def load(content = "")
        @content = content
        instance_eval @content
        result
      # In this case, since we're evaluating raw IO in the context of this
      # instance, we need to catch a wider range of exceptions.  Otherwise,
      # syntax errors would blow this up.
      rescue Exception => e # rubocop:disable Lint/RescueException
        parse_error = CommandParseError.new(e.message)
        parse_error.set_backtrace e.backtrace
        result.errors << parse_error
        result
      end

      def command(name, &block)
        new_command = GitCommander::Command.new(name, registry: registry)
        new_command.instance_exec new_command, &block
        result.commands << new_command
      rescue StandardError => e
        configuration_error = CommandConfigurationError.new(e.message)
        configuration_error.set_backtrace e.backtrace
        result.errors << configuration_error
      end
    end
  end
end
