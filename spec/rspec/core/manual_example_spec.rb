require 'spec_helper'

describe "an example" do
  matcher :be_manual_with do |message|
    match do |example|
      example.manual && example.metadata[:execution_result][:manual_message] == message
    end

    failure_message_for_should do |example|
      "expected: example manual with #{message.inspect}\n     got: #{example.metadata[:execution_result][:manual_message].inspect}"
    end
  end

  context "declared manual with metadata" do
    it "uses the value assigned to :manual as the message" do
      group = RSpec::Core::ExampleGroup.describe('group') do
        example "example", :manual => 'just because' do
        end
      end
      example = group.examples.first
      example.run(group.new, stub.as_null_object)
      example.should be_manual_with('just because')
    end

    it "sets the message to 'No reason given' if :manual => true" do
      group = RSpec::Core::ExampleGroup.describe('group') do
        example "example", :manual => true do
        end
      end
      example = group.examples.first
      example.run(group.new, stub.as_null_object)
      example.should be_manual_with('No reason given')
    end
  end

  context "with no block" do
    it "is listed as manual with 'Not yet implemented'" do
      group = RSpec::Core::ExampleGroup.describe('group') do
        it "has no block"
      end
      example = group.examples.first
      example.run(group.new, stub.as_null_object)
      example.should be_manual_with('Not yet implemented')
    end
  end

  context "with no args" do
    it "is listed as manual with the default message" do
      group = RSpec::Core::ExampleGroup.describe('group') do
        it "does something" do
          manual
        end
      end
      example = group.examples.first
      example.run(group.new, stub.as_null_object)
      example.should be_manual_with(RSpec::Core::Manual::NO_REASON_GIVEN)
    end
  end

  context "with no docstring" do
    context "declared with the manual method" do
      it "does not have an auto-generated description" do
        group = RSpec::Core::ExampleGroup.describe('group') do
          it "checks something" do
            (3+4).should eq(7)
          end
          manual do
            "string".reverse.should eq("gnirts")
          end
        end
        example = group.examples.last
        example.run(group.new, stub.as_null_object)
        example.description.should match(/example at/)
      end
    end

    context "after another example with some assertion" do
      it "does not show any message" do
        group = RSpec::Core::ExampleGroup.describe('group') do
          it "checks something" do
            (3+4).should eq(7)
          end
          specify do
            manual
          end
        end
        example = group.examples.last
        example.run(group.new, stub.as_null_object)
        example.description.should match(/example at/)
      end
    end
  end

  context "with a message" do
    it "is listed as manual with the supplied message" do
      group = RSpec::Core::ExampleGroup.describe('group') do
        it "does something" do
          manual("just because")
        end
      end
      example = group.examples.first
      example.run(group.new, stub.as_null_object)
      example.should be_manual_with('just because')
    end
  end

  context "with a block" do
    def run_example(*manual_args, &block)
      group = RSpec::Core::ExampleGroup.describe('group') do
        it "does something" do
          manual(*manual_args) { block.call if block }
        end
      end
      example = group.examples.first
      example.run(group.new, stub.as_null_object)
      example
    end

    context "that fails" do
      def run_example(*manual_args)
        super(*manual_args) { raise ArgumentError.new }
      end

      context "when given no options" do
        it "is listed as manual with the supplied message" do
          run_example("just because").should be_manual_with("just because")
        end

        it "is listed as manual with the default message when no message is given" do
          run_example.should be_manual_with(RSpec::Core::Manual::NO_REASON_GIVEN)
        end
      end

      context "when given a truthy :if option" do
        it "is listed as manual with the supplied message" do
          run_example("just because", :if => true).should be_manual_with("just because")
        end

        it "is listed as manual with the default message when no message is given" do
          run_example(:if => true).should be_manual_with(RSpec::Core::Manual::NO_REASON_GIVEN)
        end
      end

      context "when given a falsey :if option" do
        it "runs the example and fails" do
          run_example(                :if => false).should fail_with(ArgumentError)
          run_example("just because", :if => false).should fail_with(ArgumentError)
        end
      end

      context "when given a truthy :unless option" do
        it "runs the example and fails" do
          run_example(                :unless => true).should fail_with(ArgumentError)
          run_example("just because", :unless => true).should fail_with(ArgumentError)
        end
      end

      context "when given a falsey :unless option" do
        it "is listed as manual with the supplied message" do
          run_example("just because", :unless => false).should be_manual_with("just because")
        end

        it "is listed as manual with the default message when no message is given" do
          run_example(:unless => false).should be_manual_with(RSpec::Core::Manual::NO_REASON_GIVEN)
        end
      end
    end

    context "that fails due to a failed message expectation" do
      def run_example(*manual_args)
        super(*manual_args) { "foo".should_receive(:bar) }
      end

      it "passes" do
        run_example("just because").should be_manual
      end
    end

    context "that passes" do
      def run_example(*manual_args)
        super(*manual_args) { 3.should eq(3) }
      end

      context "when given no options" do
        it "fails with a ManualExampleFixedError" do
          run_example("just because").should fail_with(RSpec::Core::Manual::ManualExampleFixedError)
          run_example.should                 fail_with(RSpec::Core::Manual::ManualExampleFixedError)
        end
      end

      context "when given a truthy :if option" do
        it "fails with a ManualExampleFixedError" do
          run_example("just because", :if => true).should fail_with(RSpec::Core::Manual::ManualExampleFixedError)
          run_example(                :if => true).should fail_with(RSpec::Core::Manual::ManualExampleFixedError)
        end
      end

      context "when given a falsey :if option" do
        it "runs the example and it passes" do
          run_example(                :if => false).should pass
          run_example("just because", :if => false).should pass
        end
      end

      context "when given a truthy :unless option" do
        it "runs the example and it passes" do
          run_example(                :unless => true).should pass
          run_example("just because", :unless => true).should pass
        end
      end

      context "when given a falsey :unless option" do
        it "fails with a ManualExampleFixedError" do
          run_example("just because", :unless => false).should fail_with(RSpec::Core::Manual::ManualExampleFixedError)
          run_example(                :unless => false).should fail_with(RSpec::Core::Manual::ManualExampleFixedError)
        end
      end
    end
  end
end
