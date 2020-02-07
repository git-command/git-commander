# frozen_string_literal: true

require "spec_helper"

describe GitCommander::Plugin do
  it "initializes an Executor with the provided block" do
    source_instance = Object.new
    expect(described_class::Executor).to receive(:new).with(source_instance)
    described_class.new :git, source_instance: source_instance
  end
end
