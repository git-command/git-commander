# frozen_string_literal: true

require "rspec/mocks/matchers/receive"
require "rspec/mocks/any_instance"
require "rspec/support/differ"

module GitCommander
  module RSpec
    # Contains helper methods and matchers for testing git-commander plugins
    module PluginHelpers
      # nodoc
      class MockGemfile
        DEFAULT_GEM_SOURCE = "https://rubygems.org"

        attr_reader :gems, :options

        def initialize
          @gems = {}
          @source = DEFAULT_GEM_SOURCE
        end

        def gem(name, *options)
          @gems[name] = options || []
        end

        def source(value = nil)
          return "source: '#{@source}'" if value.nil?

          @source = value
        end

        def gemfile_lines
          [
            source,
            *@gems.map { |name, options| gem_definition(name, *options) }
          ]
        end

        def gem_definition(name, *options)
          ["gem '#{name}'", *Array(options).map { |o| gem_option_to_s(o) }].join(", ")
        end

        def gem_option_to_s(option)
          return "" if option.to_s.empty?

          case option
          when Hash
            option.map { |k, v| "#{k}: '#{v}'" }
          else
            "'#{option}'"
          end
        end
      end

      def stub_inline_gemfile
        mock_gemfile = MockGemfile.new
        allow_any_instance_of(GitCommander::Plugin::Loader).to receive(:gemfile) do |*args, &block|
          mock_gemfile.instance_eval(&block)
        end
        mock_gemfile
      end

      ::RSpec::Matchers.define :have_defined_gems do |gemfile_lines|
        gemfile_lines.map! { |l| l.gsub(/"/, "'") }
        gemfile_lines.prepend(MockGemfile.new.source) if gemfile_lines.none? { |line| line.start_with?("source:") }

        match do |block|
          mock_gemfile = stub_inline_gemfile unless GitCommander::Plugin::Loader.new(nil).is_a?(MockGemfile)

          block.call

          @actual = mock_gemfile.gemfile_lines

          values_match? gemfile_lines, @actual
        end

        diffable
        supports_block_expectations
      end
    end
  end
end
