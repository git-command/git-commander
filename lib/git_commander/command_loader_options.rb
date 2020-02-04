# frozen_string_literal: true

module GitCommander
  # Establishes values to be set by loaders
  module CommandLoaderOptions
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
  end
end
