# frozen_string_literal: true

require "fileutils"
require "stringio"
require "open3"

module CommandHelpers
  Command = Struct.new(:exit_status, :output, :error)

  def fixtures_dir
    File.expand_path "#{Dir.pwd}/spec/fixtures"
  end

  def copy_file_to_project(origin, destination)
    FileUtils.mkdir_p File.dirname(destination)
    FileUtils.cp origin, destination
  end

  def home_dir
    @home_dir ||= expand_path("home")
  end

  def project_dir
    @project_dir ||= "#{home_dir}/project"
  end

  def git_cmd_path
    File.expand_path File.join("exe", "git-cmd")
  end

  def setup_environment
    setup_home_dir
    setup_project_dir
    initialize_git_repo
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

  def initialize_git_repo
    run_system_call "touch README.md"
    run_system_call "git init ."
    run_system_call "git add README.md"
    run_system_call 'git commit -am "Initial commit"'
  end

  def setup_working_branch(branch = "master")
    run_system_call "git checkout -b #{branch}"
  end

  def make_commit(message = "Changes")
    run_system_call 'echo "Changes" >> README.md'
    run_system_call "git add README.md"
    run_system_call "git commit -am \"#{message}\""
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
    last_command.output, last_command.error, last_command.exit_status = run_in_test_context do
      Open3.capture3(command_string)
    end
  end

  def run_in_test_context(&_block)
    Dir.chdir project_dir do
      yield
    end
  end

  private

  def expand_path(path)
    File.expand_path File.join("tmp", path)
  end

  def clear_workspace
    FileUtils.rm_rf(home_dir)
  end
end
