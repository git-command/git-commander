# frozen_string_literal: true

module GitCommander
  # @abstract Wraps domain logic for executing git-cmd commands
  class Command
    attr_accessor :name, :arguments, :options

    def initialize(name, arguments: {}, **options)
      @name = name
      @arguments = arguments
      @options = options
    end

    def run(args = [])
      GitCommander.logger.info "Running '#{name}' with arguments: #{args.inspect}"
    end
  end
end
