# frozen_string_literal: true

module GitCommander
  # @abstract Wraps domain logic for executing git-cmd commands
  class Command
    attr_accessor :name, :arguments, :flags, :switches, :block

    def run
    end
  end
end
