require 'spec_helper'

describe 'Shikashi::Permissions' do
  describe '#rule' do
    let(:blk) { proc {} }
    let(:priv) { Permissions.new }
    let(:apply_rule) { priv.rule(&blk) }

    describe 'when action is given' do
      subject { apply_rule }
      let(:blk) { proc { object(Fixnum).allow_all } }
      it { is_expected.to be_nil }
    end

    describe 'when action is NOT given' do
      subject { -> { apply_rule } }
      let(:blk) { proc { object(Fixnum) } }
      it {
        msg = 'No action specified on the subject in rule.'
        is_expected.to raise_error(ArgumentError, msg)
      }
    end
  end
end