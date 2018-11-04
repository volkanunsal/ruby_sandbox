require 'spec_helper'

include RubySandbox

describe 'Whitelist' do
  describe 'return values' do
    inst = Whitelist.new

    [
      inst.allow_method(:foo),
      inst.allow_global_read(:$a),
      inst.allow_global_write(:$a),
      inst.allow_const_read(:$a),
      inst.allow_const_write(:$a),
      inst.allow_xstr,
      inst.instances_of(Fixnum).allow('foo'),
      inst.object(Fixnum).allow('foo'),
      inst.methods_of(Fixnum).allow('foo'),
      inst.instances_of(Fixnum).allow_all,
      inst.object(Fixnum).allow_all,
      inst.methods_of(Fixnum).allow_all,
    ].each do |rule|
      describe do
        subject { rule }
        it { is_expected.to be_kind_of(Whitelist) }
      end
    end
  end

  describe '#allow_method' do
    let(:method_name) { :to_s }
    subject { Whitelist.new.allow_method(method_name) }
    it { is_expected.to be_allowed(Fixnum, 4, method_name) }

    describe 'when method is a string' do
      let(:method_name) { '+' }
      it { is_expected.to be_allowed(Fixnum, 4, method_name.to_sym) }
    end
  end
end
