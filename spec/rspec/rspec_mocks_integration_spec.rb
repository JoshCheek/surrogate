require 'spec_helper'

describe 'integration with rspec-mocks' do

  let(:mp3) { Surrogate.endow(Class.new).define(:play) { }.new }

  it 'knows that rspec-mocks is loaded' do
    Surrogate::RSpec.rspec_mocks_loaded?.should equal true
  end

  context 'when rspec-mocks is loaded' do
    it 'uses their matchers' do
      mp3.play "Emily Wells"
      mp3.should have_been_told_to(:play).with(/emily/i)
      mp3.should_not have_been_told_to(:play).with(/emily/)

      mp3.play /regex/
      mp3.should have_been_told_to(:play).with(/regex/)
      mp3.should_not have_been_told_to(:play).with(/xeger/)
    end
  end

  context 'when rspec-mocks is not loaded' do
    it 'does straight #== comparisons on each argument' do
      begin
        Surrogate::RSpec.rspec_mocks_loaded = false

        mp3.play "Emily Wells"
        mp3.should_not have_been_told_to(:play).with(/emily/i)

        mp3.play /regex/
        mp3.should have_been_told_to(:play).with(/regex/)
        mp3.should_not have_been_told_to(:play).with(/xeger/)
      rescue Exception
        Surrogate::RSpec.rspec_mocks_loaded = true
      end
    end
  end
end
