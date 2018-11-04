require 'spec_helper'

describe RubySandbox::Sandbox do
  let(:priv) { RubySandbox::Whitelist.new }
  [
    '`ls`',
    '%x[ls]',
    "system('ls')",
    "exec('ls')"
  ].each do |code|
    describe code do
      let(:action) { described_class.new.run(code, priv) }
      subject { -> { action } }
      it { is_expected.to raise_error(SecurityError) }
    end
  end
end
