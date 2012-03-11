require 'spec_helper'

describe 'singing in the block' do
  it 'sings to the class' do
    pristine_klass = Class.new do
      Mockingbird.song_for self do
        sing :find, default: 123
      end
    end

    klass1 = pristine_klass.reprise
    klass1.should_not have_been_told_to :find
    klass1.find(1).should == 123
    klass1.should have_been_told_to(:find).with(1)
  end
end

describe 'recapitulation' do
  it 'a repetition or further performance of the klass' do
    pristine_klass = Class.new do
      Mockingbird.song_for self do
        sing :find, default: 123
        sing(:bind) { 'abc' }
      end
      sing :peat, default: true
      sing(:repeat) { 321 }
    end

    klass1 = pristine_klass.reprise
    klass1.should_not have_been_told_to :find
    klass1.find(1).should == 123
    klass1.should have_been_told_to(:find).with(1)
    klass1.bind.should == 'abc'

    klass2 = pristine_klass.reprise
    klass2.will_find 456
    klass2.find(2).should == 456
    klass1.find.should == 123

    klass1.should have_been_told_to(:find).with(1)
    klass2.should have_been_told_to(:find).with(2)
    klass1.should_not have_been_told_to(:find).with(2)
    klass2.should_not have_been_told_to(:find).with(1)

    klass1.new.peat.should == true
    klass1.new.repeat.should == 321
  end

  it 'is a subclass of the reprised class' do
    superclass = Mockingbird.song_for Class.new
    superclass.reprise.new.should be_a_kind_of superclass
  end
end
