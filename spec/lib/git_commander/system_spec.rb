require "spec_helper"

RSpec.describe GitCommander::System do
  before :all do
    setup_environment
  end

  after :all do
    command_helpers_teardown
  end

  describe ".run" do
    it "runs and sends output of the command to STDOUT" do
      run_in_test_context do
        output, error = capture_io do
          described_class.run "echo hi"
        end
        expect(output).to eq "hi\n"
        expect(error).to be_empty
      end
    end

    it "runs and raises a RunError" do
      run_in_test_context do
        capture_io do
          expect { described_class.run "ls chowchowracecar" }.to raise_error(GitCommander::System::RunError)
        end
      end
    end

    it "returns the output of the command" do
      run_in_test_context do
        capture_io do
          expect(described_class.run("echo hi")).to eq("hi")
        end
      end
    end

    context "when running silently" do
      it "runs and does not send output of the command to STDOUT" do
        run_in_test_context do
          output, _error = capture_io do
            expect(described_class.run("echo hi", silent: true)).to eq "hi"
          end
          expect(output).to_not include "hi"
        end
      end
    end

    context "when running non-blocking" do
      it "runs and does not send output of the command to STDOUT" do
        run_in_test_context do
          _output, error = capture_io do
            expect { described_class.run "ls chowchowracecar", blocking: false }.not_to raise_error
          end
          expect(error).to be_empty
        end
      end
    end
  end
end
