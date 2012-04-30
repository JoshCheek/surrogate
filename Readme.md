Explanation and examples coming soon, but here is a simple example I wrote up for a lightning talk:

```ruby
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
```

TODO
----

* Get a real Readme!
* Figure out whether I'm supposed to be using clone or dup for the object -.^ (looks like there may also be an `initialize_copy` method I can take advantage of instead of crazy stupid shit I'm doing now)


Features for future vuersions
-----------------------------

* arity option
* need some way to talk about and record blocks being passed
* support all rspec matchers (RSpec::Mocks::ArgumentMatchers)
* assertions for order of invocations & methods
