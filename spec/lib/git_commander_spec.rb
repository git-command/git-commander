# frozen_string_literal: true

require "spec_helper"

describe GitCommander do
  describe ".logger" do
    # Ignore memoization for tests
    before { GitCommander.instance_variable_set("@logger", nil) }

    it "initializes a new logger" do
      expect(GitCommander::Logger).to receive(:new)
      described_class.logger
    end

    it "allows for custom loggers" do
      logger = described_class.logger("tmp/kenny-loggins.log")
      expect(logger.instance_variable_get("@logdev").dev.path).to eq "tmp/kenny-loggins.log"
    end
  end
end
