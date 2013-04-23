module RSpec
  module Core
    module Blocked
      class BlockedDeclaredInExample < StandardError; end

      # If Test::Unit is loaded, we'll use its error as baseclass, so that Test::Unit
      # will report unmet RSpec expectations as failures rather than errors.
      begin
        class BlockedExampleFixedError < Test::Unit::AssertionFailedError; end
      rescue
        class BlockedExampleFixedError < StandardError; end
      end

      class BlockedExampleFixedError
        def blocked_fixed?; true; end
      end

      NO_REASON_GIVEN = 'No reason given'
      BLOCKED_TEST = 'Blocked test'

      def blocked(*args)
        return self.class.before(:each) { blocked(*args) } unless example

        options = args.last.is_a?(Hash) ? args.pop : {}
        message = args.first || NO_REASON_GIVEN

        if options[:unless] || (options.has_key?(:if) && !options[:if])
          return block_given? ? yield : nil
        end

        example.metadata[:blocked] = true
        example.metadata[:execution_result][:blocked_message] = message
        if block_given?
          begin
            result = begin
                       yield
                       example.example_group_instance.instance_eval { verify_mocks_for_rspec }
                     end
            example.metadata[:blocked] = false
          rescue Exception => e
            example.execution_result[:exception] = e
          ensure
            teardown_mocks_for_rspec
          end
          raise BlockedExampleFixedError.new if result
        end
        raise BlockedDeclaredInExample.new(message)
      end
    end
  end
end