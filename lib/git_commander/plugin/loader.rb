# frozen_string_literal: true

require "bundler/inline"
require_relative "../command/configurator"
require_relative "../loader"

module GitCommander
  class Plugin
    # @abstract Handles loading native plugins by name.
    class Loader < ::GitCommander::Loader
      class NotFoundError < StandardError; end
      class LoadError < StandardError; end

      NATIVE_PLUGIN_DIR = File.expand_path(File.join(__dir__, "..", "plugins"))

      attr_reader :content, :commands, :name

      def initialize(registry)
        @commands = []
        super
      end

      def load(name)
        @plugin = GitCommander::Plugin.new(
          resolve_plugin_name(name),
          source_instance: instance_eval(resolve_content(name))
        )
        @plugin.commands = @commands
        result.plugins << @plugin
        result.commands |= @commands
        result
      rescue Errno::ENOENT, Errno::EACCES => e
        handle_error LoadError, e
      rescue StandardError => e
        handle_error NotFoundError, e
      end

      def resolve_plugin_name(native_name_or_filename)
        return @name = native_name_or_filename if native_name_or_filename.is_a? Symbol

        @name = File.basename(native_name_or_filename).split(".").first.to_sym
      end

      def resolve_content(native_name_or_filename)
        if native_name_or_filename.is_a? Symbol
          return @content = File.read("#{NATIVE_PLUGIN_DIR}/#{native_name_or_filename}.rb")
        end

        @content = File.read(native_name_or_filename)
      end

      def command(name, &block)
        GitCommander.logger.debug("Loading command :#{name} from plugin #{@name}")
        @commands << Command::Configurator.new(registry).configure("#{plugin_name_formatted_for_cli}:#{name}".to_sym, &block)
      rescue Command::Configurator::ConfigurationError => e
        result.errors << e
      end

      def plugin(name, **options)
        plugin_result = GitCommander::Plugin::Loader.new(registry).load(name, **options)
        result.plugins |= plugin_result.plugins
      end

      private

      def plugin_name_formatted_for_cli
        @name.to_s.gsub("_", "-").to_sym
      end

      def handle_error(error_klass, original_error)
        error = error_klass.new(original_error.message)
        error.set_backtrace original_error.backtrace
        @result.errors << error
        @result
      end
    end
  end
end
