# frozen_string_literal: true

module GitCommander
  # @abstract Wraps domain logic for executing git-cmd commands
  class Command
    attr_reader :arguments, :block, :description, :flags, :switches, :name
    attr_accessor :output

    def initialize(name, registry: nil, **options)
      @name = name
      @arguments = parse_array_or_hash(options[:arguments] || {})
      @flags = parse_array_or_hash(options[:flags] || {})
      @switches = parse_array_or_hash(options[:switches] || {})
      @description = options[:description] || ""
      @block = options[:block] || proc {}
      @registry = registry || GitCommander::Registry.new
      @output = options[:output] || STDOUT
    end

    def run(args = [])
      GitCommander.logger.info "Running '#{name}' with arguments: #{args.inspect}"
    end

    def say(message)
      output.puts message
    end

    private

    def parse_array_or_hash(array_or_hash)
      return array_or_hash if array_or_hash.is_a?(Hash)

      array_or_hash.each_with_object({}) { |key, hash| hash[key] = nil }
    end
  end
end
