require 'spec_helper'

describe GitCommander::Logger do
  context "defaults" do
    it "logs to '/tmp/git-commander.log' by default" do
      logger = described_class.new
      expect(logger.instance_variable_get("@logdev").dev.path).to eq GitCommander::Logger::DEFAULT_LOG_FILE
    end
  end

  context "with a log file path configured in git config" do
    it "strips the trailing newline from the configured path" do
      FileUtils.mkdir_p "tmp"
      allow_any_instance_of(described_class).to receive(:`).
        with("git config --get commander.log-file-path").
        and_return("tmp/configured.log\n")

      logger = described_class.new

      expect(logger.instance_variable_get("@logdev").dev.path).to eq "tmp/configured.log"
    end
  end
end
