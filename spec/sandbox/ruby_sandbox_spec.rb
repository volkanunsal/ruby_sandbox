require 'spec_helper'

describe RubySandbox do
  describe '#new' do
    subject { described_class.new }
    it { is_expected.to be_kind_of(RubySandbox::Sandbox) }
  end

  describe '#build' do
    let(:args) {  }
    subject { described_class.build(args) }
    it { is_expected.to be_blacklisted(:eval) }

    describe 'args: whitelist' do
      let(:args) { :whitelist }
      it { is_expected.to be_kind_of(RubySandbox::Whitelist) }
    end
  end
end