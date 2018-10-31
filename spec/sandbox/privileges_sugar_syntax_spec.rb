require 'spec_helper'

include Shikashi

describe Whitelist, 'Shikashi::Whitelist' do
  # method chaining
  it 'allow_method should return object of Whitelist class' do
    expect(Whitelist.allow_method(:foo)).to be_kind_of(Whitelist)
  end

  it 'allow_global_read should return object of Whitelist class' do
    expect(Whitelist.allow_global_read(:$a)).to be_kind_of(Whitelist)
  end

  it 'allow_global_write should return object of Whitelist class' do
    expect(Whitelist.allow_global_write(:$a)).to be_kind_of(Whitelist)
  end

  it 'allow_const_read should return object of Whitelist class' do
    expect(Whitelist.allow_const_read(:$a)).to be_kind_of(Whitelist)
  end

  it 'allow_const_write should return object of Whitelist class' do
    expect(Whitelist.allow_const_write(:$a)).to be_kind_of(Whitelist)
  end

  it 'allow_xstr should return object of Whitelist class' do
    expect(Whitelist.allow_xstr).to be_kind_of(Whitelist)
  end

  it 'instances_of(...).allow() should return object of Whitelist class' do
    expect(Whitelist.instances_of(Fixnum).allow('foo')).to be_kind_of(Whitelist)
  end

  it 'object(...).allow() should return object of Whitelist class' do
    expect(Whitelist.object(Fixnum).allow('foo')).to be_kind_of(Whitelist)
  end

  it 'methods_of(...).allow() should return object of Whitelist class' do
    expect(Whitelist.methods_of(Fixnum).allow('foo')).to be_kind_of(Whitelist)
  end

  it 'instances_of(...).allow() should return object of Whitelist class' do
    expect(Whitelist.instances_of(Fixnum).allow_all).to be_kind_of(Whitelist)
  end

  it 'object(...).allow() should return object of Whitelist class' do
    expect(Whitelist.object(Fixnum).allow_all).to be_kind_of(Whitelist)
  end

  it 'methods_of(...).allow() should return object of Whitelist class' do
    expect(Whitelist.methods_of(Fixnum).allow_all).to be_kind_of(Whitelist)
  end

  it 'should chain one allow_method' do
    priv = Whitelist.allow_method(:to_s)
    expect(priv.allow?(Fixnum, 4, :to_s)).to be == true
  end

  it 'should chain one allow_method and one allow_global' do
    priv = Whitelist
           .allow_method(:to_s)
           .allow_global_read(:$a)

    expect(priv.allow?(Fixnum, 4, :to_s)).to be == true
    expect(priv.global_read_allowed?(:$a)).to be == true
  end

  # argument conversion
  it 'should allow + method (as string)' do
    priv = Whitelist.new
    priv.allow_method('+')
    expect(priv.allow?(Fixnum, 4, :+)).to be == true
  end

  it 'should allow + method (as symbol)' do
    priv = Whitelist.new
    priv.allow_method(:+)
    expect(priv.allow?(Fixnum, 4, :+)).to be == true
  end

  it 'should allow $a global read (as string)' do
    priv = Whitelist.new
    priv.allow_global_read('$a')
    expect(priv.global_read_allowed?(:$a)).to be == true
  end

  it 'should allow $a global read (as symbol)' do
    priv = Whitelist.new
    priv.allow_global_read(:$a)
    expect(priv.global_read_allowed?(:$a)).to be == true
  end

  it 'should allow multiple global read (as symbol) in only one allow_global_read call' do
    priv = Whitelist.new
    priv.allow_global_read(:$a, :$b)
    expect(priv.global_read_allowed?(:$a)).to be == true
    expect(priv.global_read_allowed?(:$b)).to be == true
  end

  it 'should allow $a global write (as string)' do
    priv = Whitelist.new
    priv.allow_global_write('$a')
    expect(priv.global_write_allowed?(:$a)).to be == true
  end

  it 'should allow $a global write (as symbol)' do
    priv = Whitelist.new
    priv.allow_global_write(:$a)
    expect(priv.global_write_allowed?(:$a)).to be == true
  end

  it 'should allow multiple global write (as symbol) in only one allow_global_write call' do
    priv = Whitelist.new
    priv.allow_global_write(:$a, :$b)
    expect(priv.global_write_allowed?(:$a)).to be == true
    expect(priv.global_write_allowed?(:$b)).to be == true
  end

  # constants

  it 'should allow constant read (as string)' do
    priv = Whitelist.new
    priv.allow_const_read('TESTCONSTANT')
    expect(priv.const_read_allowed?('TESTCONSTANT')).to be == true
  end

  it 'should allow constant read (as symbol)' do
    priv = Whitelist.new
    priv.allow_const_read(:TESTCONSTANT)
    expect(priv.const_read_allowed?('TESTCONSTANT')).to be == true
  end

  it 'should allow multiple constant read (as string) in only one allow_const_read call' do
    priv = Whitelist.new
    priv.allow_const_read('TESTCONSTANT1', 'TESTCONSTANT2')
    expect(priv.const_read_allowed?('TESTCONSTANT1')).to be == true
    expect(priv.const_read_allowed?('TESTCONSTANT2')).to be == true
  end

  it 'should allow constant write (as string)' do
    priv = Whitelist.new
    priv.allow_const_write('TESTCONSTANT')
    expect(priv.const_write_allowed?('TESTCONSTANT')).to be == true
  end

  it 'should allow constant write (as symbol)' do
    priv = Whitelist.new
    priv.allow_const_write(:TESTCONSTANT)
    expect(priv.const_write_allowed?('TESTCONSTANT')).to be == true
  end

  it 'should allow multiple constant write (as symbol) in only one allow_const_write call' do
    priv = Whitelist.new
    priv.allow_const_write('TESTCONSTANT1', 'TESTCONSTANT2')
    expect(priv.const_write_allowed?('TESTCONSTANT1')).to be == true
    expect(priv.const_write_allowed?('TESTCONSTANT2')).to be == true
  end
end
