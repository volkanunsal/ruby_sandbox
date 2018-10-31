require 'spec_helper'

include Shikashi

describe 'Whitelist' do
  describe 'return values' do
    [
      Whitelist.allow_method(:foo),
      Whitelist.allow_global_read(:$a),
      Whitelist.allow_global_write(:$a),
      Whitelist.allow_const_read(:$a),
      Whitelist.allow_const_write(:$a),
      Whitelist.allow_xstr,
      Whitelist.instances_of(Fixnum).allow('foo'),
      Whitelist.object(Fixnum).allow('foo'),
      Whitelist.methods_of(Fixnum).allow('foo'),
      Whitelist.instances_of(Fixnum).allow_all,
      Whitelist.object(Fixnum).allow_all,
      Whitelist.methods_of(Fixnum).allow_all,
    ].each do |rule|
      describe do
        subject { rule }
        it { is_expected.to be_kind_of(Whitelist) }
      end
    end
  end

  describe '#allow_method' do
    let(:method_name) { :to_s }
    subject { Whitelist.allow_method(method_name) }
    it { is_expected.to be_allow(Fixnum, 4, method_name) }

    describe 'when method is a string' do
      let(:method_name) { '+' }
      it { is_expected.to be_allow(Fixnum, 4, method_name.to_sym) }
    end
  end

  describe '#global_read_allowed' do
    let(:priv) { Whitelist.new }

    describe 'single var name' do
      let(:var_name) { :$a }
      subject { priv.allow_global_read(var_name) }
      it { is_expected.to be_global_read_allowed(var_name) }
      describe 'when var_name is a string' do
        let(:var_name) { '$a' }
        it { is_expected.to be_global_read_allowed(var_name.to_sym) }
      end
    end

    describe 'when multiple var names given' do
      var_names = [:$a, :$b]
      subject { priv.allow_global_read(*var_names) }
      var_names.each do |name|
        it { is_expected.to be_global_read_allowed(name) }
      end
    end
  end

  describe '#global_write_allowed' do
    let(:priv) { Whitelist.new }

    describe 'single var name' do
      let(:var_name) { :$a }
      subject { priv.allow_global_write(var_name) }
      it { is_expected.to be_global_write_allowed(var_name) }
      describe 'when var_name is a string' do
        let(:var_name) { '$a' }
        it { is_expected.to be_global_write_allowed(var_name.to_sym) }
      end
    end

    describe 'when multiple var names given' do
      var_names = [:$a, :$b]
      subject { priv.allow_global_write(*var_names) }
      var_names.each do |name|
        it { is_expected.to be_global_write_allowed(name) }
      end
    end
  end
end
