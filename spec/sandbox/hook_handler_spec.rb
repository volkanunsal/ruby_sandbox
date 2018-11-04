require 'spec_helper'
require 'evalhook'

include RubySandbox

describe 'Sandbox' do
  let(:sandbox) { Sandbox.new }
  let(:privileges) { Whitelist.new }

  describe '#hook_handler' do
    subject { sandbox }
    it { is_expected.to respond_to(:hook_handler) }
  end

  describe '#create_hook_handler' do
    let(:hook_handler) { sandbox.create_hook_handler }
    subject { hook_handler }
    it { is_expected.to be_kind_of(EvalHook::HookHandler) }
  end

  class X
    def foo; end
  end
  ::A = nil

  describe do
    before do
      allow(hook_handler).to receive(:get_caller).and_return('test-source')
    end
    let(:hook_handler) { sandbox.create_hook_handler(opts) }
    let(:opts) { unprivileged_opts }
    let(:privileged_opts) { { privileges: privileges, source: 'test-source' } }
    let(:unprivileged_opts) { { source: 'test-source' } }
    subject { -> { action }}

    [
      [
        'method calls',
        proc { hook_handler.handle_method(X, X.new, :foo) },
        proc { privileges.allow_method(:foo) }
      ],
      [
        'handle_gasgn',
        proc { hook_handler.handle_gasgn(:$a, nil) },
        proc { privileges.allow_global_write(:$a) }
      ],
      [
        'handle_cdecl',
        proc { hook_handler.handle_cdecl(Object, :A, nil) },
        proc { privileges.allow_const_write('Object::A') }
      ],
      [
        'handle_gvar',
        proc { hook_handler.handle_gvar(:$a) },
        proc { privileges.allow_global_read(:$a) }
      ],
      [
        'handle_const',
        proc { hook_handler.handle_const(:A) },
        proc { privileges.allow_const_read('A') }
      ],
    ].each do |name, action_code, privilege_code|
      describe name do
        let(:action) { instance_eval(&action_code) }

        describe 'without privileges' do
          it { is_expected.to raise_error(SecurityError) }
        end

        describe 'with privileges' do
          let(:opts) { privileged_opts }
          before do
            instance_eval(&privilege_code)
          end
          it { is_expected.to_not raise_error }
        end
      end
    end
  end
end
