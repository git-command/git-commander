# frozen_string_literal: true

require "bundler/inline"
require_relative "../loader"

module GitCommander
  class Plugin
    # @abstract Handles loading native plugins by name.
    class Loader < ::GitCommander::Loader
      class NotFoundError < StandardError; end
      class LoadError < StandardError; end

      NATIVE_PLUGIN_DIR = File.expand_path(File.join(__dir__, "..", "plugins"))

      attr_reader :content

      def load(name)
        @content = File.read("#{NATIVE_PLUGIN_DIR}/#{name}.rb")
        result.plugins << GitCommander::Plugin.new(name.to_sym, source_instance: instance_eval(@content))
        result
      rescue Errno::ENOENT, Errno::EACCES => e
        handle_error LoadError, e
      rescue StandardError => e
        handle_error NotFoundError, e
      end

      private

      def handle_error(error_klass, original_error)
        error = error_klass.new(original_error.message)
        error.set_backtrace original_error.backtrace
        @result.errors << error
        @result
      end
    end
  end
end
