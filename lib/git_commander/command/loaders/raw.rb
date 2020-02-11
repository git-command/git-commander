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
          result.commands << Configurator.new(registry).configure(name, &block)
        rescue Configurator::ConfigurationError => e
          result.errors << e
        end

        def plugin(name, **options)
          plugin_result = GitCommander::Plugin::Loader.new(registry).load(name, **options)
          result.plugins |= plugin_result.plugins
        end
      end
    end
  end
end
