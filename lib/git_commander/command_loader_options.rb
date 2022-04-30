# frozen_string_literal: true

module GitCommander
  # Establishes values to be set by loaders
  module CommandLoaderOptions
    module HelperHooks
      def add_helper_method(helper_name, &block)
        define_method(helper_name, &block)
      end
    end

    def self.included(klass)
      klass.extend HelperHooks
    end

    def summary(value = nil)
      return @summary = value if value

      @summary
    end

    def description(value = nil)
      return @description = value if value

      @description
    end

    def argument(arg_name, options = {})
      add_option :argument, options.merge(name: arg_name)
    end

    def flag(flag_name, options = {})
      add_option :flag, options.merge(name: flag_name)
    end

    def switch(switch_name, options = {})
      add_option :switch, options.merge(name: switch_name)
    end

    def on_run(&on_run)
      @block = on_run
    end

    def helpers
      @helpers ||= {}
    end

    def helper(helper_name, &block)
      self.class.add_helper_method helper_name, &block
      helpers[helper_name] = block
    end
  end
end
