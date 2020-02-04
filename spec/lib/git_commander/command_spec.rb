# frozen_string_literal: true

require "spec_helper"

describe GitCommander::Command do
  let(:output) { spy("output") }

  it "runs the block registered to it" do
    command = described_class.new(:wtf, output: output) do
      say "I'm on a boat!"
    end
    command.run
    expect(output).to have_received(:puts).with "I'm on a boat!"
  end

  it "runs the block registered to it passing arguments" do
    command = described_class.new(:wtf, output: output, arguments: [{ name: :vehicle }]) do |vehicle:|
      say "I'm on a #{vehicle}!"
    end
    command.run [GitCommander::Command::Option.new(name: :vehicle, value: "T-Rex")]
    expect(output).to have_received(:puts).with "I'm on a T-Rex!"
  end

  it "runs the block registered to it passing options" do
    command = described_class.new(
      :wtf,
      output: output,
      flags: [{ name: :make, default: "Lotus" }],
      switches: [{ name: :model }]
    ) do |params|
      say "I'm on a #{[params[:make], params[:model]].compact.join(" ")}!"
    end
    command.run [GitCommander::Command::Option.new(name: :model, value: "Evora")]
    expect(output).to have_received(:puts).with "I'm on a Lotus Evora!"
  end

  it "runs the block registered to it passing arguments and options" do
    command = described_class.new(
      :wtf,
      output: output,
      arguments: [{ name: :verb }],
      flags: [{ name: :make, default: "Lotus" }],
      switches: [{ name: :model }]
    ) do |params|
      say "I'm in a #{[params[:verb], params[:make], params[:model]].compact.join(" ")}!"
    end
    command.run [
      GitCommander::Command::Option.new(name: :verb, value: "cool"),
      GitCommander::Command::Option.new(name: :model, value: "Evora")
    ]
    expect(output).to have_received(:puts).with "I'm in a cool Lotus Evora!"
  end

  it "runs the block registered to it passing options with defaults" do
    command = described_class.new(
      :wtf,
      output: output,
      flags: [{ name: :make, default: "Lotus" }]
    ) do |params|
      say "I'm in a #{params[:make]}!"
    end
    command.run
    expect(output).to have_received(:puts).with "I'm in a Lotus!"
  end

  it "can add output" do
    command = described_class.new(:wtf, output: output)
    command.say "Ooh eeh what's up with that"
    expect(output).to have_received(:puts).with "Ooh eeh what's up with that"
  end

  it "can output a help message" do
    full_command = described_class.new(
      :start,
      arguments: [
        {
          name: :feature_branch,
          default: "new-feature",
          description: "name of the new feature branch"
        },
        {
          name: :tracking_id,
          description: "id of the story to track"
        }
      ],
      flags: [
        {
          name: :base,
          description: "name of a branch you want to branch off of"
        }
      ],
      switches: [
        {
          name: :silent,
          default: false,
          description: "supress output"
        }
      ],
      output: output,
      summary: "This will create a new feature branch and setup remote tracking",
      description: <<~LONGTIME
        Performs the following:\n
        \t$ git checkout <base_branch>\n
        \t$ git pull origin <base_branch>\n
        \t$ git push origin <base_branch>:refs/heads/[new_feature_branch]\n
        \t$ git checkout --track -b [new_feature_branch] origin/[new_feature_branch]\n
      LONGTIME
    )

    full_command.help

    expect(output).to have_received(:puts).with("NAME").ordered
    expect(output).to have_received(:puts).with("    git-cmd start – #{full_command.summary}").ordered
    expect(output).to have_received(:puts).with("USAGE").ordered
    expect(output).to have_received(:puts).with(
      "    git-cmd start [command options] [feature_branch] [tracking_id]"
    ).ordered
    expect(output).to have_received(:puts).with("DESCRIPTION").ordered
    expect(output).to have_received(:puts).with("    #{full_command.description}").ordered
    expect(output).to have_received(:puts).with("ARGUMENTS").ordered
    expect(output).to have_received(:puts).with(
      "    feature_branch – (default: \"new-feature\") name of the new feature branch"
    ).ordered
    expect(output).to have_received(:puts).with("    tracking_id – id of the story to track").ordered
    expect(output).to have_received(:puts).with("COMMAND OPTIONS")
    expect(output).to have_received(:puts).with("    [\"-b\", \"--base\"] – name of a branch you want to branch off of")
  end

  it "allows adding an argument" do
    command = described_class.new :hello, arguments: [{ name: :name }]
    command.add_option :argument, name: :greeting, default: "Heya!"
    expect(command.arguments.size).to eq 2
    expect(command.arguments.last.name).to eq :greeting
    expect(command.arguments.last.default).to eq "Heya!"
  end

  it "allows adding a flag" do
    command = described_class.new :hello, flags: [{ name: :name }]
    command.add_option :flag, name: :greeting, default: "Heya!"
    expect(command.flags.size).to eq 2
    expect(command.flags.last.name).to eq :greeting
    expect(command.flags.last.default).to eq "Heya!"
  end

  it "allows adding a switch" do
    command = described_class.new :hello, switches: [{ name: :name }]
    command.add_option :switch, name: :greeting, default: "Heya!"
    expect(command.switches.size).to eq 2
    expect(command.switches.last.name).to eq :greeting
    expect(command.switches.last.default).to eq "Heya!"
  end
end
