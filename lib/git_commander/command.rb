# frozen_string_literal: true

module GitCommander
  # @abstract Wraps domain logic for executing git-cmd commands
  class Command
    attr_accessor :name, :arguments, :options

    def initialize(name, arguments: {}, registry: nil, **options)
      @name = name
      @arguments = arguments
      @options = options
      @registry = registry || GitCommander::Registry.new
    end

    def run(args = [])
      GitCommander.logger.info "Running '#{name}' with arguments: #{args.inspect}"
    end
  end
end
