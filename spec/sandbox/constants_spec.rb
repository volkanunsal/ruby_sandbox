require 'spec_helper'

include RubySandbox

describe 'description' do
  it 'allows constant read (as string)' do
    priv = Whitelist.new
    priv.allow_const_read('TESTCONSTANT')
    expect(priv.const_read_allowed?('TESTCONSTANT')).to be == true
  end

  it 'allows constant read (as symbol)' do
    priv = Whitelist.new
    priv.allow_const_read(:TESTCONSTANT)
    expect(priv.const_read_allowed?('TESTCONSTANT')).to be == true
  end

  it 'allows multiple constant read (as string) in only one allow_const_read call' do
    priv = Whitelist.new
    priv.allow_const_read('TESTCONSTANT1', 'TESTCONSTANT2')
    expect(priv.const_read_allowed?('TESTCONSTANT1')).to be == true
    expect(priv.const_read_allowed?('TESTCONSTANT2')).to be == true
  end

  it 'allows constant write (as string)' do
    priv = Whitelist.new
    priv.allow_const_write('TESTCONSTANT')
    expect(priv.const_write_allowed?('TESTCONSTANT')).to be == true
  end

  it 'allows constant write (as symbol)' do
    priv = Whitelist.new
    priv.allow_const_write(:TESTCONSTANT)
    expect(priv.const_write_allowed?('TESTCONSTANT')).to be == true
  end

  it 'allows multiple constant write (as symbol) in only one allow_const_write call' do
    priv = Whitelist.new
    priv.allow_const_write('TESTCONSTANT1', 'TESTCONSTANT2')
    expect(priv.const_write_allowed?('TESTCONSTANT1')).to be == true
    expect(priv.const_write_allowed?('TESTCONSTANT2')).to be == true
  end
end