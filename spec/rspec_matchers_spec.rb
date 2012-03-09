require 'mockingbird'
require 'mockingbird/rspec_matchers'

describe 'RSpec matchers' do
  let(:mocked_class) { Mockingbird.song_for Class.new }

  describe 'have_been_told_to' do
    example 'default example' do
      mocked_class.sing :kick, default: []
      mock = mocked_class.new
      mock.should_not have_been_told_to :kick
      mock.kick
      mock.should have_been_told_to :kick
    end

    example 'with arguments' do
      pending
      mocked_class.sing :kick, default: []
      mock = mocked_class.new
      mock.kick 1, 2, 3
      mock.should have_been_told_to(:kick).with(1, 2, 3)
    end

    example 'multiple times' do
      mocked_class.sing :kick, default: []
      mock = mocked_class.new
      mock.should have_been_told_to(:kick).times(0)
      mock.kick
      mock.should have_been_told_to(:kick).times(1)
      mock.kick
      mock.should have_been_told_to(:kick).times(2)
    end
  end
end
