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
        plugin_executor(method_sym).respond_to?(method_sym, include_all) ||
          super(method_sym, include_all)
      end

      def method_missing(method_sym, *arguments, &block)
        return plugin_executor(method_sym) if plugin_executor(method_sym)

        super
      end

      private

      def plugin_executor(plugin_name)
        @plugin_executor ||= command.registry.find_plugin(plugin_name)&.executor
      end
    end
  end
end
