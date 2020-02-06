# frozen_string_literal: true

module GitCommander
  class Command
    # @abstract A container to execute blocks defined in command definitions
    #
    # Command @block will be executed in this class' context and methods will be
    # delegated based on methods defined here, or in plugins.
    class Runner
      attr_reader :command

      def initialize(command)
        @command = command
      end

      def run(options = {})
        GitCommander.logger.info "Running '#{command.name}' with arguments: #{options.inspect}"
        instance_exec(options, &command.block)
      end

      def say(message)
        command.say message
      end
    end
  end
end
