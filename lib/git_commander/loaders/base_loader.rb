# frozen_string_literal: true

require_relative "result"

module GitCommander
  module Loaders
    # @abstract The interface class outlining requirements for an operational Loader
    class BaseLoader
      attr_reader :registry, :result

      def initialize(registry)
        @registry = registry
        @result = Result.new
      end

      # Expected to return an instance of GitCommander::Loaders::Result
      def load(_options = {})
        raise NotImplementedError
      end
    end
  end
end
