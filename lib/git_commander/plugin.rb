# frozen_string_literal: true

require_relative "plugin/executor"

module GitCommander
  #
  # @abstract Allows for proxying methods to a plugin from within the context of
  # a Command's block.
  #
  # A Plugin provides additional external instances to a Command's @block
  # context.  Plugins can define their own inline gems, and can define
  # additional Commands.
  #
  # @example Loadable Command file with native `git` plugin
  #   # This is a unique example of using `plugin` without any options.  It
  #   # uses the `git` plugin provided natively with this gem. Most times you will
  #   # use a path: "path/to/my/plugin", or url: "https://example.com/myplugin"
  #   plugin :git
  #   command :local_branches do |cmd|
  #     git.branches.local.map(&:name)
  #   end
  #
  class Plugin
    attr_accessor :executor, :name, :registry

    # Creates a Plugin object. +name+ is the name of the plugin.
    #
    # Options include:
    #
    # +source_instance+ - an instance of an object to use in the Command's block context
    # +registry+ - a Registry instance for where this Plugin will be stored for lookup
    def initialize(name, source_instance: nil, registry: nil)
      @name = name
      @executor = Executor.new(source_instance) if source_instance
      @registry = registry || GitCommander::Registry.new
    end
  end
end
