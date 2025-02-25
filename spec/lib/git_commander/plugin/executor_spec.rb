# frozen_string_literal: true

require "stringio"
require "spec_helper"

RSpec.describe GitCommander::Plugin::Executor do
  let(:source_object) { StringIO.new }
  let(:executor) { described_class.new(source_object) }

  it "delegates methods to it's source object" do
    expect(source_object).to receive(:puts).with("hi")
    executor.puts "hi"
  end
end
