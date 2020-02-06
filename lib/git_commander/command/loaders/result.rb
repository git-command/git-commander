# frozen_string_literal: true

module GitCommander
  class Command
    module Loaders
      # @abstract A simple object to wrap errors loading any given loader
      class Result
        attr_accessor :commands, :errors

        def initialize
          @errors = []
          @commands = []
        end

        def success?
          Array(errors).empty?
        end
      end
    end
  end
end
