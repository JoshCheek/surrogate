About
=====

Handrolling mocks is the best, but involves more overhead than necessary, and usually has less helpful
error messages. Surrogate addresses this by endowing your objects with common things that most mocks need.
Currently it is only integrated with RSpec.

This codebase should be considered highly volatile until 1.0 release. The outer interface should be
fairly stable, with each 0.a.b version having backwards compatibility for any changes to b (ie
only refactorings and new features), and possible interface changes (though probably minimal)
for changes to a. Depending on the internals of the code (anything not shown in the readme) is
discouraged at this time. If you do want to do this (e.g. to make an interface for test/unit)
let me know, and I'll inform you / fork your gem and help update it, for any breaking changes
that I introduce.

New Syntax
==========

Recently (v0.5.1), a new syntax was added:

<table>
  <tr><th>Old</th><th>New</th></tr>
  <tr><td>.should have_been_told_to</td><td>.was told_to</td></tr>
  <tr><td>.should have_been_asked_for_its</td><td>.was asked_for</td></tr>
  <tr><td>.should have_been_asked_if</td><td>.was asked_if</td></tr>
  <tr><td>.should have_been_initialized_with</td><td>.was initialized_with</td></tr>
</table>

If you want to switch over, here is a shell script that should get you pretty far:

    find spec -type file |
      xargs ruby -p i .old_syntax \
      -e 'gsub /should(_not)?(\s+)have_been_told_to/,               "was\\1\\2told_to"' \
      -e 'gsub /should(_not)?(\s+)have_been_asked_(if|for)(_its)?/, "was\\1\\2asked_\\3"' \
      -e 'gsub /should(_not)(\s+)have_been_initialized_with/,       "was\\1\\2initialized_with"' \


Features
========

* Declarative syntax
* Support default values
* Easily override values
* RSpec matchers for asserting what happend (what was invoked, with what args, how many times)
* RSpec matchers for asserting the Mock's interface matches the real object
* Support for exceptions
* Queue return values
* Initialization information is always recorded


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

If you care about the **arguments**, your block can receive them.

```ruby
class MockClient
  Surrogate.endow self
  define(:request) { |limit| limit.times.map { |i| "result#{i.next}" } }
end

MockClient.new.request 3 # => ["result1", "result2", "result3"]
```

You don't need a **default if you set the ivar** of the same name (replace `?` with `_p` for predicates, since you can't have question marks in ivar names)

```ruby
class MockClient
  Surrogate.endow self
  define(:initialize) { |id| @id, @connected_p = id, true }
  define :id
  define :connected?
end
MockClient.new(12).id # => 12
```

**Override defaults** with `will_<verb>` and `will_have_<noun>`

```ruby
class MockMP3
  Surrogate.endow self
  define :play # defaults are optional, will raise error if invoked without being told what to do
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


RSpec Integration
=================

Currently only integrated with RSpec, since that's what I use. It has some builtin matchers
for querying what happened.

Load the RSpec matchers.

```ruby
require 'surrogate/rspec'
```

Nouns
-----

Given this mock and assuming the following examples happen within a spec

```ruby
class MockMP3
  Surrogate.endow self
  define(:info) { 'some info' }
end
```

Check if **was invoked** with `have_been_asked_for_its`

```ruby
mp3.should_not have_been_asked_for_its :info
mp3.info
mp3.should have_been_asked_for_its :info
```

Invocation **cardinality** by chaining `times(n)`

```ruby
mp3.info
mp3.info
mp3.should have_been_asked_for_its(:info).times(2)
```

Invocation **arguments** by chaining `with(args)`

```ruby
mp3.info :title
mp3.should have_been_asked_for_its(:info).with(:title)
```

Supports RSpec's `no_args` matcher (the others coming in future versions)

```ruby
mp3.info
mp3.should have_been_asked_for_its(:info).with(no_args)
```

Cardinality of a specific set of args `with(args)` and `times(n)`

```ruby
mp3.info :title
mp3.info :title
mp3.info :artist
mp3.should have_been_asked_for_its(:info).with(:title).times(2)
mp3.should have_been_asked_for_its(:info).with(:artist).times(1)
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

Check if **was invoked** with `have_been_told_to`

```ruby
mp3.should_not have_been_told_to :play
mp3.play
mp3.should have_been_told_to :play
```

Also supports the same `with(args)` and `times(n)` that nouns have.


Initialization
--------------

Query with `have_been_initialized_with`, which is exactly the same as saying `have_been_told_to(:initialize).with(...)`

```ruby
class MockUser
  Surrogate.endow self
  define(:initialize) { |id| @id = id }
  define :id
end
user = MockUser.new 12
user.id.should == 12
user.should have_been_initialized_with 12
```


Predicates
----------

Query qith `have_been_asked_if`, all the same chainable methods from above apply.

```ruby
class MockUser
  Surrogate.endow self
  define(:admin?) { false }
end

user = MockUser.new
user.should_not be_admin
user.will_have_admin? true
user.should be_admin
user.should have_been_asked_if(:admin?).times(2)
```


class MockUser

Substitutability
----------------

After you've implemented the real version of your mock (assuming a [top-down](http://vimeo.com/31267109) style of development),
how do you prevent your real object from getting out of synch with your mock?

Assert that your mock has the **same interface** as your real class.
This will fail if the mock inherits methods which are not on the real class. It will also fail
if the real class has any methods which have not been defined on the mock or inherited by the mock.

Presently, it will ignore methods defined directly in the mock (as it adds quite a few of its own methods,
and generally considers them to be helpers). In a future version, you will be able to tell it to treat other methods
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
MockUser.should substitute_for User

# mock has extra method
MockUser.define :name
MockUser.should_not substitute_for User

# the same again via inheritance
class UserWithName < User
  def name()end
end
MockUser.should substitute_for UserWithName

# real class has extra methods
class UserWithNameAndAddress < UserWithName
  def address()end
end
MockUser.should_not substitute_for UserWithNameAndAddress
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
MockUser.should substitute_for User, subset: true

# but now it fails b/c it has no address
MockUser.define :address
MockUser.should_not substitute_for User, subset: true
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

    service.should have_been_told_to(:create).with { |block|
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
* [Corey Haines](http://coreyhaines.com/) for pairing on substitutability with me
* [Enova](http://www.enovafinancial.com/) for giving me time and motivation to work on this during Enova Labs.
* [8th Light](http://8thlight.com/) for giving me time to work on this during our weekly Wazas, and the general encouragement and interest


TODO
----

* Remove dependency on all of RSpec and only depend on rspec-core, then have AC tests for the other shit
* Move surrogates to be first class and defined in the classes that use them.
* Add proper failure messages for block invocations
* Add a better explanation for motivations
* Figure out whether I'm supposed to be using clone or dup for the object -.^ (looks like there may also be an `initialize_copy` method I can take advantage of instead of crazy stupid shit I'm doing now)
* don't blow up when delegating to the Object#initialize with args (do I still want this, or do I want to force arity matching (and maybe even variable name matching)?)
* config: rspec_mocks loaded, whether unprepared blocks should raise or just return nil
* extract surrogate/rspec into its own gem
* support subset-substitutabilty not being able to touch real methods (e.g. #respond_to?)
* Add a last_instance option so you don't have to track it explicitly


Future Features
---------------

* figure out how to talk about callbacks like #on_success
* have some sort of reinitialization that can hook into setup/teardown steps of test suite
* Support arity checking as part of substitutability
* Ability to disassociate the method name from the test (e.g. you shouldn't need to change a test just because you change a name)
* ability to declare normal methods as being part of the API
* ability to declare a define that uses the overridden method as the body, but can still act like an api method
* assertions for order of invocations & methods
* class generator? (supports a top-down style of development for when you write your mocks before you write your implementations)
* deal with hard dependency on rspec-mocks
