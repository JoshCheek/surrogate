require 'erb'


class Mockingbird
  module RSpec
    module MessagesFor

      MESSAGES = {
        verb: {
          should: {
            default:    "was never told to <%= subject %>",
            with:       "should have been told to <%= subject %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
            times:      "should have been told to <%= subject %> <%= times_msg expected_times_invoked %> but was told to <%= subject %> <%= times_msg times_invoked %>",
            with_times: "should have been told to <%= subject %> <%= times_msg expected_times_invoked %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
          },
          should_not: {
            default:    "shouldn't have been told to <%= subject %>, but was told to <%= subject %> <%= times_msg times_invoked %>",
            with:       "should not have been told to <%= subject %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
            times:      "shouldn't have been told to <%= subject %> <%= times_msg expected_times_invoked %>, but was",
            with_times: "should not have been told to <%= subject %> <%= times_msg expected_times_invoked %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
          },
          other: {
            not_invoked: "was never told to",
            invoked_description: "got it",
          },
        },
        noun: {
          should: {
            default:    "was never asked for its <%= subject %>",
            with:       "should have been asked for its <%= subject %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
            times:      "should have been asked for its <%= subject %> <%= times_msg expected_times_invoked %>, but was asked <%= times_msg times_invoked %>",
            with_times: "should have been asked for its <%= subject %> <%= times_msg expected_times_invoked %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
          },
          should_not: {
            default:    "shouldn't have been asked for its <%= subject %>, but was asked <%= times_msg times_invoked %>",
            with:       "should not have been asked for its <%= subject %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
            times:      "shouldn't have been asked for its <%= subject %> <%= times_msg expected_times_invoked %>, but was",
            with_times: "should not have been asked for its <%= subject %> <%= times_msg expected_times_invoked %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
          },
          other: {
            not_invoked: "was never asked",
            invoked_description: "was asked",
          },
        },
      }

      def message_for(language_type, message_category, message_type, binding)
        message = MESSAGES[language_type][message_category].fetch(message_type)
        ERB.new(message).result(binding)
      end

      def inspect_arguments(arguments)
        inspected_arguments = arguments.map { |argument| MessagesFor.inspect_argument argument }
        inspected_arguments << 'no_args' if inspected_arguments.empty?
        %Q(`#{inspected_arguments.join ", "}')
      end

      def inspect_argument(to_inspect)
        if to_inspect.kind_of? ::RSpec::Mocks::ArgumentMatchers::NoArgsMatcher
          "no_args"
        else
          to_inspect.inspect
        end
      end

      extend self
    end


    class Handler < Struct.new(:subject, :language_type)
      attr_accessor :instance, :message_type

      def message_for(message_category, message_type)
        MessagesFor.message_for(language_type, message_category, message_type, binding)
      end

      def inspect_arguments(args)
        MessagesFor.inspect_arguments args
      end

      def message_type
        @message_type || :default
      end

      def invocations
        instance.invocations(subject)
      end

      def times_invoked
        invocations.size
      end

      def match?
        times_invoked > 0
      end

      def times_msg(n)
        "#{n} time#{'s' unless n == 1}"
      end

      def failure_message_for_should
        message_for :should, message_type
      end

      def failure_message_for_should_not
        message_for :should_not, message_type
      end
    end


    module MatchWithArguments
      def self.extended(klass)
        klass.message_type = :with
      end

      attr_accessor :expected_arguments

      def match? # eventually this will need to get a lot smarter
        if expected_arguments.size == 1 && expected_arguments.first.kind_of?(::RSpec::Mocks::ArgumentMatchers::NoArgsMatcher)
          invocations.include? []
        else
          invocations.include? expected_arguments
        end
      end

      def actual_invocation
        return message_for :other, :not_invoked if times_invoked.zero?
        inspected_invocations = invocations.map { |invocation| inspect_arguments invocation }
        "got #{inspected_invocations.join ', '}"
      end
    end


    module MatchNumTimes
      def self.extended(klass)
        klass.message_type = :times
      end

      attr_accessor :expected_times_invoked

      def match?
        expected_times_invoked == times_invoked
      end
    end


    module MatchNumTimesWith
      def self.extended(klass)
        klass.message_type = :with_times
      end

      attr_accessor :expected_times_invoked, :expected_arguments

      def times_invoked_with_expected_args
        invocations.select { |invocation| invocation == expected_arguments }.size
      end

      def match?
        times_invoked_with_expected_args == expected_times_invoked
      end

      def actual_invocation
        return message_for :other, :not_invoked if times_invoked.zero?
        "#{message_for :other, :invoked_description} #{times_msg times_invoked_with_expected_args}"
      end
    end





    # have_been_told_to
    ::RSpec::Matchers.define :have_been_told_to do |verb|
      use_case = Handler.new verb, :verb

      match do |mocked_instance|
        use_case.instance = mocked_instance
        use_case.match?
      end

      chain :times do |number|
        use_case.extend (use_case.kind_of?(MatchWithArguments) ? MatchNumTimesWith : MatchNumTimes)
        use_case.expected_times_invoked = number
      end

      chain :with do |*arguments|
        use_case.extend (use_case.kind_of?(MatchNumTimes) ? MatchNumTimesWith : MatchWithArguments)
        use_case.expected_arguments = arguments
      end

      failure_message_for_should     { use_case.failure_message_for_should }
      failure_message_for_should_not { use_case.failure_message_for_should_not }
    end


    # have_been_asked_for_its
    ::RSpec::Matchers.define :have_been_asked_for_its do |noun|
      use_case = Handler.new noun, :noun

      match do |mocked_instance|
        use_case.instance = mocked_instance
        use_case.match?
      end

      chain :times do |number|
        use_case.extend (use_case.kind_of?(MatchWithArguments) ? MatchNumTimesWith : MatchNumTimes)
        use_case.expected_times_invoked = number
      end

      chain :with do |*arguments|
        use_case.extend (use_case.kind_of?(MatchNumTimes) ? MatchNumTimesWith : MatchWithArguments)
        use_case.expected_arguments = arguments
      end

      failure_message_for_should     { use_case.failure_message_for_should }
      failure_message_for_should_not { use_case.failure_message_for_should_not }
    end


    # have_been_initialized_with
    ::RSpec::Matchers.define :have_been_initialized_with do |*init_args|
      use_case = Handler.new :initialize, :verb
      use_case.extend MatchWithArguments
      use_case.expected_arguments = init_args

      match do |mocked_instance|
        use_case.instance = mocked_instance
        use_case.match?
      end

      chain :nothing do
        use_case.expected_arguments = nothing
      end

      failure_message_for_should do
        use_case.failure_message_for_should
      end

      failure_message_for_should_not do
        use_case.failure_message_for_should_not
      end
    end
  end
end


