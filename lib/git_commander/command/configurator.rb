# frozen_string_literal: true

module GitCommander
  class Command
    # Allows configuring a [GitCommander::Command] with a block
    class Configurator
      class ConfigurationError < StandardError; end

      attr_reader :registry

      def initialize(registry)
        @registry = registry
      end

      def configure(name, &block)
        new_command = GitCommander::Command.new(name, registry: registry)
        new_command.instance_exec new_command, &block if block_given?
        new_command
      rescue StandardError => e
        configuration_error = ConfigurationError.new(e.message)
        configuration_error.set_backtrace e.backtrace
        raise configuration_error
      end
    end
  end
end
