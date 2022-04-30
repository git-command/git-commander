# frozen_string_literal: true

module GitCommander
  class Command
    # @abstract A container to execute blocks defined in command definitions
    #
    # Command @block will be executed in this class' context and methods will be
    # delegated based on methods defined here, or in plugins.
    class Runner
      attr_reader :command

      undef :system

      def initialize(command)
        @command = command
      end

      def run(options = {})
        GitCommander.logger.info "Running '#{command.name}' with arguments: #{options.inspect}"
        instance_exec(**options, &command.block)
      end

      def say(message)
        command.say message
      end

      def respond_to_missing?(method_sym, include_all = false)
        binding.irb if method_sym == :git
        plugin_executor(method_sym).respond_to?(method_sym, include_all) ||
          has_helper?(method_sym) ||
          super(method_sym, include_all)
      end

      def method_missing(method_sym, *arguments, &block)
        binding.irb if method_sym == :git
        return plugin_executor(method_sym) if plugin_executor(method_sym)
        return run_helper(method_sym, *arguments) if has_helper?(method_sym)

        super
      end

      private

      def plugin_executor(plugin_name)
        @plugin_executor ||= command.registry.find_plugin(plugin_name)&.executor
      end

      def has_helper?(helper_name)
        command.helpers.has_key?(helper_name)
      end

      def run_helper(helper_name, *arguments)
        GitCommander.logger.info "Running helper '#{helper_name}' with arguments: #{arguments.inspect}"
        instance_exec(arguments, &command.helpers[helper_name])
      end
    end
  end
end
