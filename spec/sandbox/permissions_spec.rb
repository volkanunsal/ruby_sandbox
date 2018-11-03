require 'spec_helper'

describe 'RubySandbox::Permissions' do
  describe '#rule' do
    let(:blk) { proc {} }
    let(:priv) { Permissions.new }
    let(:apply_rule) { priv.rule(&blk) }

    describe 'when action is given' do
      subject { apply_rule }
      let(:blk) { proc { |s| s.object(Fixnum).allow_all } }
      it { is_expected.to be_kind_of(Permissions) }
    end

    describe 'when action is NOT given' do
      subject { -> { apply_rule } }
      let(:blk) { proc { |s| s.object(Fixnum) } }
      it {
        msg = 'No action specified on the subject in rule.'
        is_expected.to raise_error(ArgumentError, msg)
      }
    end
  end

  describe '#global_read_allowed' do
    let(:priv) { Permissions.new }

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
    let(:priv) { Permissions.new }

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