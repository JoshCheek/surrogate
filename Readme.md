Explanation and examples coming soon.

TODO
----

* substitutability
* add methods for substitutability


Features for future vuersions
-----------------------------

* change queue notation from will_x_qeue(1,2,3) to will_x(1,2,3)
* arity option
* support for raising errors
* need some way to talk about and record blocks being passed
* support all rspec matchers (RSpec::Mocks::ArgumentMatchers)
* assertions for order of invocations & methods



Future subset substitutability

    # =====  Substitutability  =====

    # real user is not a suitable substitute if missing methods that mock user has
    user_class.should_not substitute_for Class.new

    # real user must have all of mock user's methods to be substitutable
    substitutable_real_user_class = Class.new do
      def self.find() end
      def initialize(id) end
      def id() end
      def name() end
      def address() end
      def phone_numbers() end
      def add_phone_number(area_code, number) end
    end
    user_class.should substitute_for substitutable_real_user_class
    user_class.should be_subset_of substitutable_real_user_class

    # real user class is not a suitable substitutable if has extra methods, but is suitable subset
    real_user_class = substitutable_real_user_class.clone
    def real_user_class.some_class_meth() end
    user_class.should_not substitute_for real_user_class
    user_class.should be_subset_of real_user_class

    real_user_class = substitutable_real_user_class.clone
    real_user_class.send(:define_method, :some_instance_method) {}
    user_class.should_not substitute_for real_user_class
    user_class.should be_subset_of real_user_class

    # subset substitutability does not work for superset
    real_user_class = substitutable_real_user_class.clone
    real_user_class.undef_method :address
    user_class.should_not be_subset_of real_user_class
