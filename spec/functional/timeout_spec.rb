require 'spec_helper'

describe RubySandbox::Sandbox do
  [
    ['basic', 0.2, 0.1],
    ['float', 0.2, 0.1],
    ['float_no_hit', 0.1, 0.2],
    ['zero', 0.1, 0],
    ['zero_no_hit', 0, 1]
    ].each do |name, execution_delay, timeout|
      describe name do
        let(:action) {
          code = "sleep #{execution_delay}"
          Sandbox.new.run code, priv, timeout: timeout
        }
        subject { -> { action } }
        let(:priv) { RubySandbox::Whitelist.new }
        before { priv.allow_method :sleep }

        if timeout == 0
          it { is_expected.to raise_error(ArgumentError) }
        elsif execution_delay > timeout
          it { is_expected.to raise_error(RubySandbox::TimeoutError) }
        else
          it { is_expected.to_not raise_error }
        end
      end
  end
end
