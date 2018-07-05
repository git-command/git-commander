require 'spec_helper'

describe GitCommander::Logger do
  context "defaults" do
    it "logs to '/tmp/git-commander.log' by default" do
      logger = described_class.new
      expect(logger.instance_variable_get("@logdev").dev.path).to eq GitCommander::Logger::DEFAULT_LOG_FILE
    end
  end
end
