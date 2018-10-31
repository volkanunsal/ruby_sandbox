require 'spec_helper'

describe Shikashi do
  describe '#new' do
    subject { described_class.new }
    it { is_expected.to be_kind_of(Shikashi::Sandbox) }
  end

  describe '#build' do
    let(:args) {  }
    subject { described_class.build(args) }
    it { is_expected.to be_blacklisted(:eval) }

    describe 'args: whitelist' do
      let(:args) { :whitelist }
      it { is_expected.to be_kind_of(Shikashi::Whitelist) }
    end
  end
end