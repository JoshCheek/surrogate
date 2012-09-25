require 'spec_helper'

describe 'mapping method names to ivars' do
  let(:mocked_class) { Surrogate.endow Class.new }

  [ :[]   ,  '@_brackets',
    :**   ,  '@_splat_splat',
    :'!@' ,  '@_ubang',
    :'+@' ,  '@_uplus',
    :'-@' ,  '@_uminus',
    :*    ,  '@_splat',
    :/    ,  '@_divide',
    :%    ,  '@_percent',
    :+    ,  '@_plus',
    :-    ,  '@_minus',
    :>>   ,  '@_shift_right',
    :<<   ,  '@_shift_left',
    :&    ,  '@_ampersand',
    :^    ,  '@_caret',
    :|    ,  '@_bang',
    :<=   ,  '@_less_eq',
    :<    ,  '@_less',
    :>    ,  '@_greater',
    :>=   ,  '@_greater_eq',
    :<=>  ,  '@_spaceship',
    :==   ,  '@_2eq',
    :===  ,  '@_3eq',
    :!=   ,  '@_not_eq',
    :=~   ,  '@_eq_tilde',
    :!~   ,  '@_bang_tilde',
  ].each_slice 2 do |method_name, ivar|
    it "maps #{method_name} to #{ivar}" do
      mocked_class.define method_name
      instance = mocked_class.new
      instance.instance_variable_set ivar, 123
      instance.send method_name
    end
  end
end
