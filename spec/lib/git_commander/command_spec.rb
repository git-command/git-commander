# frozen_string_literal: true

describe GitCommander::Command do
  it "runs the block registered to it"
  it "runs the block registered to it passing arguments"
  it "runs the block registered to it passing options"
  it "runs the block registered to it passing arguments and options"
  it "runs the block registered to it passing options with defaults"
  it "can add output" do
    output = spy("output")
    command = described_class.new(:wtf, output: output)
    command.say "Ooh eeh what's up with that"
    expect(output).to have_received(:puts).with "Ooh eeh what's up with that"
  end
end
