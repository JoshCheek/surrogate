class Surrogate
  module RSpec
    class WithFilter
      class BlockAsserter
        class RaiseAsserter
          def initialize(arg, message)
            @assertion = if arg.kind_of? String
                           match_message arg
                         elsif arg.kind_of? Regexp
                           match_regexp arg
                         elsif exception_and_message? arg, message
                           match_exception_and_message arg, message
                         else
                           raise ArgumentError, "raising(#{arg.inspect}, #{message.inspect}) are not valid arguments"
                         end
          end

          def call(exception)
            @assertion.call exception
          end

          private

          def exception_and_message?(exception_class, message)
            return false unless exception_class.kind_of? Class
            return false unless exception_class.ancestors.include? Exception
            return false unless message.kind_of?(NilClass) || message.kind_of?(String) || message.kind_of?(Regexp)
            true
          end

          def match_message(message)
            -> exception { message == exception.message }
          end

          def match_regexp(regexp)
            -> exception { regexp =~ exception.message }
          end

          def match_exception_and_message(exception_class, message)
            -> exception do
              return false unless exception.kind_of? exception_class
              return message == exception.message if message.kind_of? String
              return message =~ exception.message if message.kind_of? Regexp
              true
            end
          end
        end
      end

      class BlockAsserter
        def initialize(definition_block)
          @call_with = Invocation.new []
          definition_block.call self
        end

        def call_with(*args, &block)
          @call_with = Invocation.new args, &block
        end

        def returns(value=nil, &block)
          @returns = block || lambda { |returned| returned.should == value }
        end

        def before(&block)
          @before = block
        end

        def after(&block)
          @after = block
        end

        # arg can be a string      (expected message)
        #            a regex       (matches the actual message)
        #            an exception  (type of exception expected to be raised)
        def raising(arg, message=nil)
          @raising = RaiseAsserter.new arg, message
        end

        def arity(n)
          @arity = n
        end

        def matches?(block_to_test)
          matches   = before_matches?       block_to_test
          matches &&= return_value_matches? block_to_test
          matches &&= arity_matches?        block_to_test
          matches &&= after_matches?        block_to_test
          matches
        end

        private

        # matches if no return specified, or returned value == specified value
        # also matches the block
        def return_value_matches?(block_to_test)
          returned_value = block_to_test.call(*@call_with.args, &@call_with.block)
          @returns.call returned_value if @returns
          @raising.nil?
        rescue ::RSpec::Expectations::ExpectationNotMetError
          false
        rescue Exception # !!!!!!WARNING!!!!!! (look here if things go wrong)
          @raising && @raising.call($!)
        end

        # matches if the first time it is called, it raises nothing
        def before_matches?(*)
          @before_has_been_invoked || (@before && @before.call)
        ensure
          return @before_has_been_invoked = true unless $!
        end

        # matches if nothing is raised
        def after_matches?(block_to_test)
          @after && @after.call
          true
        end

        def arity_matches?(block_to_test)
          return true unless @arity
          block_to_test.arity == @arity
        end

        attr_accessor :block_to_test
      end
    end
  end
end
