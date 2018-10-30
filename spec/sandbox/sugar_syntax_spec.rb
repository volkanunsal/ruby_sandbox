require 'spec_helper'

include Shikashi

describe Sandbox, 'Shikashi sandbox' do
  it 'should allow single run' do
    expect(Sandbox.run('0')).to be == 0
  end

  it 'should allow single run with empty privileges' do
    priv = Privileges.new
    expect(Sandbox.run('0', priv)).to be == 0
  end

  it 'should allow single run with privileges allowing + method (as symbol)' do
    priv = Privileges.new
    priv.allow_method :+
    expect(Sandbox.run('1+1', priv)).to be == 2
  end

  it 'should allow single run with privileges allowing + method (as string)' do
    priv = Privileges.new
    priv.allow_method '+'
    expect(Sandbox.run('1+1', priv)).to be == 2
  end

  it 'should allow single run with privileges using sugar syntax and allowing + method (as symbol)' do
    expect(Sandbox.run('1+1', Privileges.allow_method(:+))).to be == 2
  end

  it 'should allow single run with privileges using sugar syntax and allowing + method (as string)' do
    expect(Sandbox.run('1+1', Privileges.allow_method('+'))).to be == 2
  end
end
