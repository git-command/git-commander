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

  it "allows registering commands with arguments" do
    registry.register :wtf, arguments: { first: nil, second: nil }
    wtf_command = registry.commands[:wtf]
    expect(wtf_command).to be
    expect(wtf_command.arguments).to eql(first: nil, second: nil)
  end

  it "allows registering commands with flags" do
    registry.register :wtf, arguments: %i[first second], flags: { raise_hell: false }
    wtf_command = registry.commands[:wtf]
    expect(wtf_command).to be
    expect(wtf_command.arguments).to eql(first: nil, second: nil)
    expect(wtf_command.flags).to eql(raise_hell: false)
  end

  it "allows registering commands with switches" do
    registry.register :wtf, arguments: %i[first second], flags: { raise_hell: false }, switches: { clobber: true }
    wtf_command = registry.commands[:wtf]
    expect(wtf_command).to be
    expect(wtf_command.arguments).to eql(first: nil, second: nil)
    expect(wtf_command.flags).to eql(raise_hell: false)
    expect(wtf_command.switches).to eql(clobber: true)
  end

  it "allows describing a command" do
    registry.register(:wtf, description: "WTF is up with x")
    wtf_command = registry.commands[:wtf]
    expect(wtf_command).to be
    expect(wtf_command.description).to eq("WTF is up with x")
  end

  it "allows re-registering existing commands" do
    registry.register(:wtf, arguments: { day: :today })
    wtf_command = registry.commands[:wtf]
    expect(wtf_command.arguments).to eq(day: :today)
    registry.register(:wtf, arguments: { message: nil })
    expect(registry.find(:wtf).arguments).to eq(message: nil)
  end

  it "allows looking up a registered command" do
    expected_command = registry.register(:wtf)
    expect(registry.find(:wtf)).to eq expected_command
  end

  it "raises an error when trying to find a command that is not registered" do
    expect { registry.find(:wtf) }.to raise_error GitCommander::Registry::CommandNotFound
  end
end
