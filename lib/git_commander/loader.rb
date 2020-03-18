# frozen_string_literal: true

require "bundler/inline"
require_relative "loader_result"

module GitCommander
  # @abstract The interface class outlining requirements for an operational Loader
  class Loader
    # Let the loaders proxy system calls in the git-commander context
    undef :system

    attr_reader :registry, :result

    def initialize(registry)
      @registry = registry
      @result = LoaderResult.new
    end

    # Expected to return an instance of GitCommander::LoaderResult
    def load(_options = {})
      raise NotImplementedError
    end

    def system
      GitCommander::System
    end
  end
end
