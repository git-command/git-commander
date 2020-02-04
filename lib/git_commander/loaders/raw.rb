# frozen_string_literal: true

module GitCommander
  module Loaders
    # @abstract Handles loading commands from raw strings
    class Raw < BaseLoader
      attr_reader :content

      def load(content = "")
        @content = content
        instance_eval @content
        Result.new
      end

      def command(name, &block)
        new_command = GitCommander::Command.new(name)
        new_command.instance_exec new_command, &block
        registry.register_command new_command
      end
    end
  end
end
