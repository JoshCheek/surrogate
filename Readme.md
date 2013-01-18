[![Build Status](https://secure.travis-ci.org/JoshCheek/surrogate.png?branch=master)](http://travis-ci.org/JoshCheek/surrogate)



About
=====

Handrolling mocks is the best, but involves more overhead than necessary, and usually has less helpful
error messages. Surrogate addresses this by endowing your objects with common things that most mocks need.
Currently it is only integrated with RSpec.

This codebase should be considered volatile until 1.0 release. The outer interface should be
fairly stable, with each 0.a.b version having backwards compatibility for any changes to b (ie
only refactorings and new features), and possible interface changes (though probably minimal)
for changes to a. Depending on the internals of the code (anything not shown in the readme) is
discouraged at this time. If you do want to do this (e.g. to make an interface for test/unit)
let me know, and I'll inform you / fork your gem and help update it, for any breaking changes
that I introduce.

Features
========

* Mock does not diverge from real class because compares signatures of mocks to signatures of the real class.
* Support default values
* Easily override values
* RSpec matchers for asserting what happend (what was invoked, with what args, how many times)
* RSpec matchers for asserting the Mock's interface matches the real object
* Support for exceptions
* Queue return values


Usage
=====

**Endow** a class with surrogate abilities

```ruby
class Mock
  Surrogate.endow self
end
```

Define a **class method** by using `define` in the block when endowing your class.

```ruby
class MockClient
  Surrogate.endow self do
    define(:default_url) { 'http://example.com' }
  end
end

MockClient.default_url # => "http://example.com"
```

Define an **instance method** by using `define` outside the block after endowing your class.

```ruby
class MockClient
  Surrogate.endow self
  define(:request) { ['result1', 'result2'] }
end

MockClient.new.request # => ["result1", "result2"]
```

Ruby's `attr_accessor`, `attr_reader`, `attr_writer` are mimicked with `define_accessor`, `define_reader`, `define_writer`.
You can pass a block to `define_accessor` and `define_reader` if you would like to give it a default_value.

```ruby
class MockClient
  Surrogate.endow self
  define_accessor :default_url
end

client = MockClient.new
client.default_url # => nil
client.default_url = 'http://whatever.com'
client.default_url # => "http://whatever.com"
```

If you expect **arguments**, your block should receive them.
This prevents the issues with dynamic mocks where arguments and parameters can diverge.
It may seem like more work when you have to write the arguments explicitly, but you only
need to do this once, and then you can be sure they match on each invocation.

```ruby
class MockClient
  Surrogate.endow self
  define(:request) { |limit| limit.times.map { |i| "result#{i.next}" } }
end

MockClient.new.request 3 # => ["result1", "result2", "result3"]
```

You don't need a **default if you set the ivar** of the same name (replace `?` with `_p` for predicates, and `!` with `_b` for bang methods, since you can't have question marks or bangs in ivar names).

```ruby
class MockClient
  Surrogate.endow self
  define(:initialize) { |id| @id, @connected_p, @reconnect_b = id, true, true }
  define :id
  define :connected?
  define :reconnect!
end
MockClient.new(12).id # => 12
```

**Override defaults** with `will_<verb>` and `will_have_<noun>`

```ruby
class MockMP3
  Surrogate.endow self
  define :play # default behavior is to do nothing, same as empty block yielding nothing
  define :info
end

mp3 = MockMP3.new

# verbs
mp3.will_play true
mp3.play # => true

# nouns
mp3.will_have_info artist: 'Symphony of Science', title: 'Children of Africa'
mp3.info # => {:artist=>"Symphony of Science", :title=>"Children of Africa"}
```

**Errors** get raised

```ruby
class MockClient
  Surrogate.endow self
  define :request
end

client = MockClient.new
client.will_have_request StandardError.new('Remote service unavailable')

begin
  client.request
rescue StandardError => e
  e # => #<StandardError: Remote service unavailable>
end
```

**Queue** up return values

```ruby
class MockPlayer
  Surrogate.endow self
  define(:move) { 20 }
end

player = MockPlayer.new
player.will_move 1, 9, 3
player.move # => 1
player.move # => 9
player.move # => 3
```

You can define **initialize**

```ruby
class MockUser
  Surrogate.endow self do
    define(:find) { |id| new id }
  end
  define(:initialize) { |id| @id = id }
  define(:id) { @id }
end

user = MockUser.find 12
user.id # => 12
```

Use **clone** to avoid altering state on the class.
You can pass it key/value pairs to mass initialize the clone
(I think it's probably best to avoid this kind of state on classes, but do support it)
```ruby
class MockUser
  Surrogate.endow self do
    define(:find) { new }
  end
end

# using a clone
user_class = MockUser.clone
user_class.find
user_class.was told_to :find
MockUser.was_not told_to :find

# initializing the clone
MockUser.clone(find: nil).find.should be_nil
```

**Mass initialize** with `.factory(key: value)`, this can be turned off by passing
`factory: false` as an option to Surrogate.endow, or given a different name if
the value is the new name.

```ruby
# default factory method
class MockUserWithFactory
  Surrogate.endow self
  define(:name) { 'Samantha' }
  define(:age)  { 83 }
end

user = MockUserWithFactory.factory name: 'Jim', age: 26
user.name # => "Jim"
user.age  # => 26

# use a different name
class MockUserWithRenamedFactory
  Surrogate.endow self, factory: :construct
  define(:name) { 'Samantha' }
  define(:age)  { 83 }
end

user = MockUserWithRenamedFactory.construct name: 'Milla'
user.name # => "Milla"
user.age  # => 83
```


RSpec Integration
=================

Currently only integrated with RSpec, since that's what I use. It has some builtin matchers
for querying what happened.

Load the RSpec matchers.

```ruby
require 'surrogate/rspec'
```

Last Instance
-------------

Access the last instance of a class

```ruby
class MockMp3
  Surrogate.endow self
end

mp3_class = MockMp3.clone # because you don't want to mutate the singleton
mp3 = mp3_class.new
mp3_class.last_instance.equal? mp3 # => true
```

Nouns
-----

Given this mock and assuming the following examples happen within a spec

```ruby
class MockMP3
  Surrogate.endow self
  define(:info) { |song='Birds Will Sing Forever'| 'some info' }
end
```

Check if **was invoked** with `was asked_for` (`was` is an alias of `should`, and `asked_for` is a custom matcher)

```ruby
mp3.was_not asked_for :info
mp3.info
mp3.was asked_for :info
```

Invocation **cardinality** by chaining `times(n)`

```ruby
mp3.info
mp3.info
mp3.was asked_for(:info).times(2)
```

Invocation **arguments** by chaining `with(args)`

```ruby
mp3.info :title
mp3.was asked_for(:info).with(:title)
```

Supports RSpec's matchers (`no_args`, `hash_including`, etc)

```ruby
mp3.info
mp3.was asked_for(:info).with(no_args)
```

Cardinality of a specific set of args `with(args)` and `times(n)`

```ruby
mp3.info :title
mp3.info :title
mp3.info :artist
mp3.was asked_for(:info).with(:title).times(2)
mp3.was asked_for(:info).with(:artist).times(1)
```


Verbs
-----

Given this mock and assuming the following examples happen within a spec

```ruby
class MockMP3
  Surrogate.endow self
  define(:play) { true }
end
```

Check if **was invoked** with `was told_to`

```ruby
mp3.was_not told_to :play
mp3.play
mp3.was told_to :play
```

Also supports the same `with(args)` and `times(n)` that nouns have.


Initialization
--------------

Query with `was initialized_with`, which is exactly the same as saying `was told_to(:initialize).with(...)`

```ruby
class MockUser
  Surrogate.endow self
  define(:initialize) { |id| @id = id }
  define :id
end
user = MockUser.new 12
user.id.should == 12
user.was initialized_with 12
```


Predicates
----------

Query qith `was asked_if`, all the same chainable methods from above apply.

```ruby
class MockUser
  Surrogate.endow self
  define(:admin?) { false }
end

user = MockUser.new
user.should_not be_admin
user.will_have_admin? true
user.should be_admin
user.was asked_if(:admin?).times(2)
```


Substitutability
----------------

Facets of substitutability: method existence, argument types, (and soon argument names)

After you've implemented the real version of your mock (assuming a [top-down](http://vimeo.com/31267109) style of development),
how do you prevent your real object from getting out of synch with your mock?

Assert that your mock has the **same interface** as your real class.
This will fail if the mock inherits methods which are not on the real class. It will also fail
if the real class has any methods which have not been defined on the mock or inherited by the mock.

Presently, it will ignore methods defined directly in the mock (as it considers them to be helpers).
In a future version, you will be able to tell it to treat other methods
as part of the API (will fail if they don't match, and maybe record their values).

```ruby
class User
  def initialize(id)end
  def id()end
end

class MockUser
  Surrogate.endow self
  define(:initialize) { |id| @id = id }
  define :id
end

# they are the same
User.should substitute_for MockUser

# they differ
MockUser.define :name
User.should_not substitute_for MockUser

# signatures don't match (you can turn this off by passing `types: false` to substitute_for)
class UserWithWrongSignature
  def initialize()end # no id
  def id()end
end
UserWithWrongSignature.should_not substitute_for MockUser

# parameter names don't match
class UserWithWrongParamNames
  def initialize(name)end # real one takes an id
  def id()end
end
UserWithWrongParamNames.should_not substitute_for MockUser, names: true
```

Sometimes you don't want to have to implement the entire interface.
In these cases, you can assert that the methods on the mock are a **subset**
of the methods on the real class.

```ruby
class User
  def initialize(id)end
  def id()end
  def name()end
end

class MockUser
  Surrogate.endow self
  define(:initialize) { |id| @id = id }
  define :id
end

# doesn't matter that real user has a name as long as it has initialize and id
User.should substitute_for MockUser, subset: true

# but now it fails b/c it has no address
MockUser.define :address
User.should_not substitute_for MockUser, subset: true
```


Blocks
------

When your method is invoked with a block, you can make assertions about the block.

_Note: Right now, block error messages have not been addressed (which means they are probably confusing as shit)_

Before/after hooks (make assertions here)

```ruby
class MockService
  Surrogate.endow self
  define(:create) {}
end

describe 'something that creates a user through the service' do
  let(:old_id) { 12 }
  let(:new_id) { 123 }

  it 'updates the user_id and returns the old_id' do
    user_id = old_id
    service = MockService.new

    service.create do |user|
      to_return = user_id
      user_id = user[:id]
      to_return
    end

    service.was told_to(:create).with { |block|
      block.call_with({id: new_id})              # this will be given to the block
      block.returns old_id                       # provide a return value, or a block that receives the return value (where you can make assertions)
      block.before { user_id.should == old_id }  # assertions about state of the world before the block is called
      block.after  { user_id.should == new_id }  # assertions about the state of the world after the block is called
    }
  end
end
```


How do I introduce my mocks?
============================

This is known as dependency injection. There are many ways you can do this, you can pass the object into
the initializer, you can pass a factory to your class, you can give the class that depends on the mock a
setter and then override it whenever you feel it is necessary, you can use RSpec's `#stub` method to put
it into place.

Personally, I use [Deject](https://rubygems.org/gems/deject), another gem I wrote. For more on why I feel
it is a better solution than the above methods, see it's [readme](https://github.com/JoshCheek/deject/tree/938edc985c65358c074a7c7b7bbf18dc11e9450e#why-write-this).


But why write this?
===================

Need to put an explanation here soon. In the meantime, I wrote a [blog](http://blog.8thlight.com/josh-cheek/2011/11/28/three-reasons-to-roll-your-own-mocks.html) that touches on the reasons.


Special Thanks
==============

* [Kyle Hargraves](https://github.com/pd) for changing the name of his internal gem so that I could take Surrogate
* [David Chelimsky](http://blog.davidchelimsky.net/) for pairing with me to make Surrogate integrate better with RSpec
* [Enova](http://www.enovafinancial.com/) for giving me time and motivation to work on this during Enova Labs.
* [8th Light](http://8thlight.com/) for giving me time to work on this during our weekly Wazas, and the general encouragement and interest
* The people who have paired with me on this: [Corey Haines](http://coreyhaines.com/) on substitutability, [Kori Roys](https://github.com/koriroys) on `#last_instance`, [Wai Lee](https://github.com/skatenerd) on the new assertion syntax
* The people who have contributed: [Michael Baker](with m://github.com/michaelbaker) on the readme.
