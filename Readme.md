Explanation and examples coming soon, but here is a simple example I wrote up for a lightning talk:

    require 'surrogate'
    require 'surrogate/rspec'

    module Mock
      class User
        Surrogate.endow self
        define(:name) { 'Josh' }
        define :phone_numbers
        define :add_phone_number do |area_code, number|
          @phone_numbers << [area_code, number]
        end
      end
    end

    class User
      def name()end
      def phone_numbers()end
      def add_phone_number()end
    end

    describe do
      it 'ensures the mock lib looks like real lib' do
        Mock::User.should substitute_for User
      end

      let(:user) { Mock::User.new }

      example 'you can tell it how to behave and ask what happened with it' do
        user.will_have_name "Sally"

        user.should_not have_been_asked_for_its :name
        user.name.should == "Sally"
        user.should have_been_asked_for_its :name
      end
    end




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
