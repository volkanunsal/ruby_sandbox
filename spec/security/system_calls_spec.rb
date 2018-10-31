require 'spec_helper'

describe RubySandbox::Sandbox, 'RubySandbox sandbox' do
  it 'should raise SecurityError when try to run shell cmd with backsticks' do
    priv = RubySandbox::Whitelist.new
    expect do
      RubySandbox::Sandbox.new.run('`ls`', priv)
    end.to raise_error(SecurityError)
  end

  it 'should raise SecurityError when try to run shell cmd with percent' do
    priv = RubySandbox::Whitelist.new
    expect do
      RubySandbox::Sandbox.new.run('%x[ls]', priv)
    end.to raise_error(SecurityError)
  end

  it 'should raise SecurityError when try to run shell cmd by calling system method' do
    priv = RubySandbox::Whitelist.new
    expect do
      RubySandbox::Sandbox.new.run("system('ls')", priv)
    end.to raise_error(SecurityError)
  end

  it 'should raise SecurityError when try to run shell cmd by calling exec method' do
    priv = RubySandbox::Whitelist.new
    expect do
      RubySandbox::Sandbox.new.run("exec('ls')", priv)
    end.to raise_error(SecurityError)
  end
end
