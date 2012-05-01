About
=====

Handrolling mocks is the best, but involves more overhead than necessary, and usually has less helpful
error messages. Surrogate addresses this by endowing your objects with common things that most mocks need.
Currently it is only integrated with RSpec.


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

Define a class method by using `define` in the block when endowing your class.

```ruby
lass MockClient
  Surrogate.endow self do
    define(:default_url) { 'http://example.com' }
  end
end

MockClient.default_url # => "http://example.com"
```

Define an instance method by using `define` outside the block after endowing your class.

```ruby
class MockClient
  Surrogate.endow self
  define(:request) { ['result1', 'result2'] }
end

MockClient.new.request # => ["result1", "result2"]
```

If you care about the arguments, your block can receive them.

```ruby
class MockClient
  Surrogate.endow self
  define(:request) { |limit| limit.times.map { |i| "result#{i.next}" } }
end

MockClient.new.request 3 # => ["result1", "result2", "result3"]
```

You don't need a default if you set the ivar of the same name

```ruby
class MockClient
  Surrogate.endow self
  define(:initialize) { |id| @id = id }
  define :id
end
MockClient.new(12).id # => 12
```

Override defaults with `will_<verb>` and `will_have_<noun>`

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

Errors get raised

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

Queue up return values

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

# then back to default behaviour
player.move # => 20
```

You can define initialize

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

Given this mock

```ruby
class MockMP3
  Surrogate.endow self
  define(:info) { 'some info' }
end
```

Query with `have_been_asked_for_its`

```ruby
mp3.should_not have_been_asked_for_its :info
mp3.info
mp3.should have_been_asked_for_its :info
```

Invocation cardinality by chaining `times(n)`

```ruby
mp3.info
mp3.info
mp3.should have_been_asked_for_its(:info).times(2)
```

Invocation arguments by chaining `with(args)`

```ruby
mp3.info :title
mp3.should have_been_asked_for_its(:info).with(:title)
```

Supports RSpec's `no_args` matcher (the others coming in future versions)

```ruby
mp3.info
mp3.should have_been_asked_for_its(:info).with(no_args)
```

Some set of args some set of times by chaining `with(args)` and `times(n)`

```ruby
mp3.info :title
mp3.info :title
mp3.info :artist
mp3.should have_been_asked_for_its(:info).with(:title).times(2)
mp3.should have_been_asked_for_its(:info).with(:artist).times(1)
```


Verbs
-----

Given this mock

```ruby
class MockMP3
  Surrogate.endow self
  define(:play) { true }
end
```

Query with `have_been_told_to`

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

Initialization is always recorded, so that you don't have to override it just to get it to record the args.

```ruby
class MockUser < Struct.new(:id)
  Surrogate.endow self
end
user = MockUser.new 12
user.id.should == 12
user.should have_been_initialized_with 12
```


Substitutability
----------------

After you've implemented the real version of your mock (assuming a [top-down](http://vimeo.com/31267109) style of development),
how do you prevent your real object from getting out of synch with your mock?

Assert that your mock has the same interface as your real class.
This will fail if the mock inherits methods methods not on the real class. And it will fail
if the real class has or lacks any methods defined on the mock or inherited by the mock.

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
In these cases, you can assert that the methods on the mock are a subset
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

# but now it fails b/c it has no addres
MockUser.define :address
MockUser.should_not substitute_for User, subset: true
```


But why?
========

Need to put an explanation here soon. In the meantime, I wrote a [blog](http://blog.8thlight.com/josh-cheek/2011/11/28/three-reasons-to-roll-your-own-mocks.html) that touches on the reasons.


TODO
----

* Get a real Readme!
* Figure out whether I'm supposed to be using clone or dup for the object -.^ (looks like there may also be an `initialize_copy` method I can take advantage of instead of crazy stupid shit I'm doing now)


Future Features
---------------

* Support all RSpec matchers (hash_including, anything, etc)
* have some sort of reinitialization that can hook into setup/teardown steps
* Support arity checking as part of substitutability
* Support for blocks
* Ability to disassociate the method name from the test (e.g. you shouldn't need to change a test just because you change a name)


Features for future versions
----------------------------

* arity option
* need some way to talk about and record blocks being passed
* support all rspec matchers (RSpec::Mocks::ArgumentMatchers)
* assertions for order of invocations & methods
