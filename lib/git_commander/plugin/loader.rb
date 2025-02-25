# frozen_string_literal: true

require_relative "../command/configurator"
require_relative "../loader"

module GitCommander
  class Plugin
    # @abstract Handles loading native plugins by name.
    class Loader < ::GitCommander::Loader
      class LoadError < StandardError; end
      class NullPlugin < GitCommander::Plugin; end

      NATIVE_PLUGIN_DIR = File.expand_path(File.join(__dir__, "..", "plugins"))

      attr_reader :content, :name

      def initialize(registry)
        super
      end

      def load(plugin_name)
        existing_plugin = registry.find_plugin(plugin_name)
        return existing_plugin if existing_plugin

        plugin = GitCommander::Plugin.new(resolve_plugin_name(plugin_name), registry: registry)
        GitCommander.logger.debug("[Plugin Loader] Loading '#{plugin_name}' with: '#{plugin_file(plugin_name)}'")
        plugin.executor = GitCommander::Plugin::Executor.new(
          instance_eval(resolve_content(plugin_name), plugin_file(plugin_name), 1)
        )
        registry.register_plugin(plugin)
      rescue StandardError => e
        handle_plugin_error(plugin, e)
      end

      def command(command_name, &block)
        GitCommander.logger.debug("[Plugin loader] Registering command '#{command_name}' from plugin '#{@name}'")
        registry.register_command(
          Command::Configurator.new(registry).configure(
            "#{plugin_name_formatted_for_cli}:#{command_name}".to_sym,
            &block
          )
        )
      rescue Command::Configurator::ConfigurationError => e
        registry.errors[:plugins][name] ||= []
        registry.errors[:plugins][name] << e
      end

      def plugin(plugin_name, **options)
        existing_plugin = registry.find_plugin(plugin_name)
        return existing_plugin if existing_plugin

        GitCommander.logger.debug("[Plugin Loader] Loading '#{plugin_name}' from plugin '#{@name}'")
        GitCommander::Plugin::Loader.new(registry).load(plugin_name, **options)
      end

      def gemfile(install = false, options = {}, &gemfile)
        GitCommander.logger.debug("[#{name} plugin] Loading depndencies from gemfile...")
        Bundler.with_original_env do
          super(install, options, &gemfile)
        end
      end

      def gem(gem_name, *args)
        GitCommander.logger.debug "[#{name} plugin] Adding gem: #{gem_name}, #{args}..."
        Dir.chdir(GitCommander.root) do
          options = args.last.is_a?(Hash) ? args.pop.dup : {}
          options[:group] = :git_commands

          bundle_command = ["bundle add #{gem_name}"]
          bundle_command << "-v #{args[0]}" unless args[0].to_s.empty?
          bundle_command << "-g #{options[:group]}" unless options[:group].to_s.empty?
          bundle_command << "-s #{options[:source]}" unless options[:source].to_s.empty?
          bundle_command << "--git" if options.key?(:git)
          bundle_command << "--branch" if options.key?(:branch)
          bundle_command << "--skip-install" if options.key?(:skip_install)
          bundle_command << "--optimistic" if options.key?(:optimistic)
          bundle_command << "--strict" if options.key?(:strict)
          system.run bundle_command.join(" ")
        end
      end

      private

      def plugin_file(native_name_or_filename)
        @plugin_file ||= if native_name_or_filename.is_a? Symbol
                           "#{NATIVE_PLUGIN_DIR}/#{native_name_or_filename}.rb"
                         else
                           native_name_or_filename
                         end
      end

      def resolve_plugin_name(native_name_or_filename)
        @name = File.basename(plugin_file(native_name_or_filename)).split(".").first.to_sym
      end

      def resolve_content(native_name_or_filename)
        @content = File.read(plugin_file(native_name_or_filename), mode: "rb", encoding: Encoding::UTF_8)
        @content = File.read(plugin_file(native_name_or_filename), mode: "rb", encoding: Encoding::default_external) unless @content.valid_encoding?
        @content = File.read(plugin_file(native_name_or_filename), mode: "rb") unless @content.valid_encoding?
        @content
      end

      def plugin_name_formatted_for_cli
        @name.to_s.gsub("_", "-").to_sym
      end

      def handle_plugin_error(plugin, original_error)
        error = LoadError.new(original_error.message)
        error.set_backtrace original_error.backtrace
        registry.errors[:plugins][name] ||= []
        registry.errors[:plugins][name] << error
        plugin
      end
    end
  end
end
