# frozen_string_literal: true

require_relative "../configurator"
require_relative "../../loader"
require_relative "../../plugin/loader"

module GitCommander
  class Command
    module Loaders
      # @abstract Handles loading commands from raw strings
      class Raw < ::GitCommander::Loader
        class CommandParseError < StandardError; end

        attr_reader :content

        def load(content = "")
          @content = content
          instance_eval @content
          registry
        # In this case, since we're evaluating raw IO in the context of this
        # instance, we need to catch a wider range of exceptions.  Otherwise,
        # syntax errors would blow this up.
        rescue Exception => e # rubocop:disable Lint/RescueException
          parse_error = CommandParseError.new(e.message)
          parse_error.set_backtrace e.backtrace
          registry.errors[:commands][:_raw_commands] ||= []
          registry.errors[:commands][:_raw_commands] << parse_error
          registry
        end

        def command(name, &block)
          registry.register_command(
            Configurator.new(registry).configure(name, &block)
          )
        rescue Configurator::ConfigurationError => e
          command = Configurator.new(registry).configure(name)
          log_comamnd_error(command, e)
          command
        end

        def plugin(name, **options)
          GitCommander::Plugin::Loader.new(registry).load(name, **options)
        end

        def commands
          registry.commands
        end

        def plugins
          registry.plugins
        end

        private

        def log_comamnd_error(command, original_error)
          error = CommandParseError.new(original_error.message)
          error.set_backtrace original_error.backtrace
          registry.errors[:commands][command.name] ||= []
          registry.errors[:commands][command.name] << error
        end

        def log_plugin_error
        end
      end
    end
  end
end
