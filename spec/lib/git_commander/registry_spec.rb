# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/git_commander/registry"

describe GitCommander::Registry do
  let(:registry) { described_class.new }

  it "allows registering commands" do
    expect(registry.commands[:wtf]).to_not be
    registry.register(:wtf)
    expect(registry.commands[:wtf]).to be
  end

  it "allows registering commands with arguments"
  it "allows registering commands with flags"
  it "allows registering commands with switches"
  it "allows re-registering existing commands" do
    registry.register(:wtf, arguments: { day: :today })
    expect(registry.commands[:wtf][:arguments]).to eq(day: :today)
    registry.register(:wtf, arguments: { message: nil })
    expect(registry.commands[:wtf][:arguments]).to eq(message: nil)
  end

  it "allows looking up a registered command" do
    expected_command = registry.register(:wtf)
    expect(registry.find(:wtf)).to eq expected_command
  end

  it "raises an error when trying to find a command that is not registered" do
    expect { registry.find(:wtf) }.to raise_error GitCommander::Registry::CommandNotFound
  end
end
