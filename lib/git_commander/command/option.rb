# frozen_string_literal: true

module GitCommander
  class Command
    # @nodoc
    class Option
      attr_reader :default, :description, :name
      attr_writer :value

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
