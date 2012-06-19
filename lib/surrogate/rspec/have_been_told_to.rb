require 'surrogate/rspec/invocation_matcher'

class Surrogate
  module RSpec
    class HaveBeenToldTo < InvocationMatcher
      MESSAGES = {
        should: {
          default:    "was never told to <%= method_name %>",
          with:       "should have been told to <%= method_name %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
          times:      "should have been told to <%= method_name %> <%= times_msg expected_times_invoked %> but was told to <%= method_name %> <%= times_msg invocations.size %>",
          with_times: "should have been told to <%= method_name %> <%= times_msg expected_times_invoked %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
          },
        should_not: {
          default:    "shouldn't have been told to <%= method_name %>, but was told to <%= method_name %> <%= times_msg invocations.size %>",
          with:       "should not have been told to <%= method_name %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
          times:      "shouldn't have been told to <%= method_name %> <%= times_msg expected_times_invoked %>, but was",
          with_times: "should not have been told to <%= method_name %> <%= times_msg expected_times_invoked %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
        },
      }
    end
  end
end
