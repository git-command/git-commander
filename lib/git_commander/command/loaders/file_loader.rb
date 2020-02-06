# frozen_string_literal: true

require_relative "base"

module GitCommander
  class Command
    module Loaders
      # @abstract Handles loading commands from file
      class FileLoader < Base
        class FileNotFoundError < StandardError; end
        class FileLoadError < StandardError; end

        attr_reader :filename

        def load(filename)
          raw_loader = Raw.new(registry)
          @result = raw_loader.load(File.read(filename))
        rescue Errno::ENOENT => e
          handle_error FileNotFoundError, e
        rescue StandardError => e
          handle_error FileLoadError, e
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
end
