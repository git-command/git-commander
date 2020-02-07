# frozen_string_literal: true

module GitCommander
  # @abstract A simple object to wrap errors loading any given loader
  class LoaderResult
    attr_accessor :commands, :plugins, :errors

    def initialize
      @errors = []
      @commands = []
      @plugins = []
    end

    def success?
      Array(errors).empty?
    end
  end
end
