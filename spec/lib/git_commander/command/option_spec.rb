# frozen_string_literal: true

require "spec_helper"

describe GitCommander::Command::Option do
  describe "#value" do
    it "falls back to the default when no value is set" do
      option = described_class.new(name: :answer, default: "Because racecar.")
      expect(option.value).to eq "Because racecar."
    end

    it "returns the assigned value when one is set" do
      option = described_class.new(name: :answer, default: "Because racecar.")
      option.value = "Because zombies."
      expect(option.value).to eq "Because zombies."
    end

    it "prefers an explicitly assigned false over a truthy default" do
      option = described_class.new(name: :loud, default: true)
      option.value = false
      expect(option.value).to be false
    end
  end

  describe "equality" do
    it "treats options with the same name, default, and description as equal" do
      option = described_class.new(name: :question, default: "Why?", description: "The question")
      twin = described_class.new(name: :question, default: "Why?", description: "The question")

      expect(option).to eql twin
      expect(option.hash).to eq twin.hash
    end

    it "de-duplicates equal options in a Set" do
      option = described_class.new(name: :question)
      twin = described_class.new(name: :question)

      expect(Set.new([option, twin]).size).to eq 1
    end
  end
end
