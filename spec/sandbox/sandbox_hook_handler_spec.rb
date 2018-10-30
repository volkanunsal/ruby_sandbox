require 'spec_helper'
require 'evalhook'

include Shikashi

describe Sandbox, 'Shikashi sandbox hook handler' do
  it 'should be obtainable from sandbox' do
    Sandbox.new.hook_handler
  end

  it 'should be obtainable from sandbox through create_hook_handler' do
    sandbox = Sandbox.new
    hook_handler = sandbox.create_hook_handler
    expect(hook_handler).to be_kind_of(EvalHook::HookHandler)
  end

  class X
    def foo; end
  end
  it 'should raise SecurityError when handle calls without privileges' do
    sandbox = Sandbox.new
    hook_handler = sandbox.create_hook_handler

    x = X.new
    expect do
      hook_handler.handle_method(X, x, :foo)
    end.to raise_error(SecurityError)
  end

  it 'should not raise SecurityError with method privileges' do
    sandbox = Sandbox.new
    priv = Privileges.new
    priv.allow_method(:foo)

    hook_handler = sandbox.create_hook_handler(privileges: priv, source: 'test-source')

    def hook_handler.get_caller
      'test-source'
    end

    x = X.new
    expect do
      hook_handler.handle_method(X, x, :foo)
    end.to_not raise_error
  end

  it 'should raise SecurityError with handle_gasgn without privileges' do
    sandbox = Sandbox.new

    hook_handler = sandbox.create_hook_handler(source: 'test-source')

    def hook_handler.get_caller
      'test-source'
    end

    expect do
      hook_handler.handle_gasgn(:$a, nil)
    end.to raise_error(SecurityError)
  end

  it 'should not raise SecurityError with handle_gasgn with privileges' do
    sandbox = Sandbox.new
    privileges = Privileges.new

    privileges.allow_global_write(:$a)

    hook_handler = sandbox.create_hook_handler(privileges: privileges, source: 'test-source')

    def hook_handler.get_caller
      'test-source'
    end

    expect do
      hook_handler.handle_gasgn(:$a, nil)
    end.to_not raise_error
  end

  it 'should raise SecurityError with handle_cdecl without privileges' do
    sandbox = Sandbox.new

    hook_handler = sandbox.create_hook_handler(source: 'test-source')

    def hook_handler.get_caller
      'test-source'
    end

    expect do
      hook_handler.handle_cdecl(Object, :A, nil)
    end.to raise_error(SecurityError)
  end

  it 'should not raise SecurityError with handle_cdecl with privileges' do
    sandbox = Sandbox.new
    privileges = Privileges.new

    privileges.allow_const_write('Object::A')

    hook_handler = sandbox.create_hook_handler(privileges: privileges, source: 'test-source')

    def hook_handler.get_caller
      'test-source'
    end

    expect do
      hook_handler.handle_cdecl(Object, :A, nil)
    end.to_not raise_error
  end

  it 'should raise SecurityError with handle_gvar without privileges' do
    sandbox = Sandbox.new

    hook_handler = sandbox.create_hook_handler(source: 'test-source')

    def hook_handler.get_caller
      'test-source'
    end

    expect do
      hook_handler.handle_gvar(:$a)
    end.to raise_error(SecurityError)
  end

  it 'should not raise SecurityError with handle_gasgn with privileges' do
    sandbox = Sandbox.new
    privileges = Privileges.new

    privileges.allow_global_read(:$a)

    hook_handler = sandbox.create_hook_handler(privileges: privileges, source: 'test-source')

    def hook_handler.get_caller
      'test-source'
    end

    expect do
      hook_handler.handle_gvar(:$a)
    end.to_not raise_error
  end

  it 'should raise SecurityError with handle_const without privileges' do
    sandbox = Sandbox.new

    hook_handler = sandbox.create_hook_handler(source: 'test-source')

    def hook_handler.get_caller
      'test-source'
    end

    expect do
      hook_handler.handle_const(:A)
    end.to raise_error(SecurityError)
  end

  it 'should not raise SecurityError with handle_cdecl with privileges' do
    sandbox = Sandbox.new
    privileges = Privileges.new

    ::A = nil
    privileges.allow_const_read('A')

    hook_handler = sandbox.create_hook_handler(privileges: privileges, source: 'test-source')

    def hook_handler.get_caller
      'test-source'
    end

    expect do
      hook_handler.handle_const(:A)
    end.to_not raise_error
  end
end
