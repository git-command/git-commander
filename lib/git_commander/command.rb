# frozen_string_literal: true

module GitCommander
  # @abstract Wraps domain logic for executing git-cmd commands
  class Command
    attr_reader :arguments, :block, :description, :flags, :name, :options, :summary, :switches
    attr_accessor :output

    # @nodoc
    class Option
      attr_reader :default, :description, :name
      attr_writer :value

      def initialize(name:, default: nil, description: nil)
        @name = name.to_sym
        @default = default
        @description = description
      end

      def value
        @value || @default
      end

      def ==(other)
        other.class == self.class &&
          other.name == name &&
          other.default == default &&
          other.description == description
      end
      alias eql? ==
    end

    def initialize(name, registry: nil, **options, &block)
      @name = name
      @description = options[:description]
      @summary = options[:summary]
      @block = block_given? ? block : proc {}
      @registry = registry || GitCommander::Registry.new
      @output = options[:output] || STDOUT

      define_command_options(options)
    end

    def run(run_options = [])
      GitCommander.logger.info "Running '#{name}' with arguments: #{@options.inspect}"
      instance_exec(run_options, &@block)
    end

    def say(message)
      output.puts message
    end

    def help
      say "NAME"
      say "    git-cmd #{name} – #{summary}"
      say "USAGE"
      say "    git-cmd #{name} [command options] #{arguments.map { |arg| "[#{arg.name}]" }.join(" ")}"
      description_help
      argument_help
      options_help
    end

    private

    def define_command_options(options)
      @arguments = options_from_hash(options[:arguments])
      @flags = options_from_hash(options[:flags])
      @switches = options_from_hash(options[:switches])
      @options = Set.new(@arguments + @flags + @switches)
    end

    def options_from_hash(hash)
      Array(hash).map { |v| Option.new(**v) }
    end

    def description_help
      return if description.to_s.empty?

      say "DESCRIPTION"
      say "    #{description}"
    end

    def argument_help
      return unless arguments.any?

      say "ARGUMENTS"
      arguments.each do |argument|
        default_text = argument.default.nil? ? "" : "(default: #{argument.default.inspect}) "
        say "    #{argument.name} – #{default_text}#{argument.description}"
      end
    end

    def options_help
      return unless flags.any? || switches.any?

      say "COMMAND OPTIONS"
      flag_help
      switch_help
    end

    def flag_help
      flags.each do |flag|
        flag_names = ["-#{flag.name.to_s[0]}", "--#{flag.name}"]
        say "    #{flag_names} – #{flag.default.nil? ? "" : "(default: #{flag.default})  "}#{flag.description}"
      end
    end

    def switch_help
      switches.each do |switch|
        switch_names = [switch.name.to_s[0], "-#{switch.name}"].map { |s| "-#{s}" }.join(", ")
        say "    #{switch_names} – #{switch.default.nil? ? "" : "(default: #{switch.default})  "}#{switch.description}"
      end
    end
  end
end
