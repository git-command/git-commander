# frozen_string_literal: true

module GitCommander
  module Loaders
    # @abstract A simple object to wrap errors loading any given loader
    class Result
      attr_accessor :errors

      def initialize
        @errors = []
      end

      def success?
        Array(errors).empty?
      end
    end
  end
end
