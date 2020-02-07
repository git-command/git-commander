# frozen_string_literal: true

module GitCommander
  class Command
    # @abstract Wraps [Command] arguments, flags, and switches in a generic
    #           object to normalize their representation in the context of a
    #           [Command].
    class Option
      attr_reader :default, :description, :name
      attr_writer :value

      # Creates a [Option] object.
      #
      # @param name [String, Symbol] the name of the option, these are unique per [Command]
      # @param default [anything] the default value the option should have
      # @param description [String] a description of the option for display in
      #        the [Command]'s help text
      # @param value [anything] a value for the option
      def initialize(name:, default: nil, description: nil, value: nil)
        @name = name.to_sym
        @default = default
        @description = description
        @value = value
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

      def to_h
        { name => value }
      end
    end
  end
end
