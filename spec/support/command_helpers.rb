# frozen_string_literal: true

require "fileutils"
require "stringio"

module CommandHelpers
  Command = Struct.new(:exit_status, :output, :error)

  def setup_environment
    setup_home_dir
    setup_project_dir
  end

  def last_command
    @last_command ||= Command.new
  end

  def setup_home_dir
    @original_home = ENV.fetch("HOME")
    FileUtils.mkdir_p home_dir
    ENV["HOME"] = home_dir
  end

  def setup_project_dir
    FileUtils.mkdir_p project_dir
  end

  def command_helpers_teardown
    ENV["HOME"] = @original_home || "~/"
    clear_workspace
  end

  # Credit: Minitest
  # https://github.com/seattlerb/minitest/blob/100e82a4de148348fc87a6b09292079635eb9503/lib/minitest/assertions.rb#L459
  def capture_io
    captured_stdout = StringIO.new
    captured_stderr = StringIO.new

    orig_stdout = $stdout
    orig_stderr = $stderr
    $stdout = captured_stdout
    $stderr = captured_stderr

    yield

    [captured_stdout.string, captured_stderr.string]
  ensure
    $stdout = orig_stdout
    $stderr = orig_stderr
  end

  def run_system_call(command_string)
    output, error = capture_io do
      last_command.exit_status = execute_command_in_test_context(arguments) ? 0 : 1
    end

    last_command.output = output
    last_command.error = error
  end

  private

  def execute_command_in_test_context
    Dir.chdir project_dir do
      yield
    end
  end

  def home_dir
    expand_path "home"
  end

  def project_dir
    expand_path "project"
  end

  def expand_path(path)
    File.expand_path File.join("tmp", path)
  end

  def clear_workspace
    FileUtils.rm_rf(home_dir)
  end

  before :suite do
    setup_environment
  end

  after :suite do
    command_helpers_teardown
  end
end
