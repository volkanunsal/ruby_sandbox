require 'spec_helper'

include Shikashi

describe Sandbox, 'Shikashi sandbox' do
  def self.add_test(name, execution_delay, timeout)
    if execution_delay > timeout
      it "Should allow timeout of type #{name}" do
        priv = Shikashi::Whitelist.new
        priv.allow_method :sleep

        expect do
          Sandbox.new.run "sleep #{execution_delay}", priv, timeout: timeout
        end.to raise_error(Shikashi::Timeout::Error)
      end
    else
      it "Should allow timeout of type #{name}" do
        priv = Shikashi::Whitelist.new
        priv.allow_method :sleep

        Sandbox.new.run "sleep #{execution_delay}", priv, timeout: timeout
      end
    end
  end

  add_test 'basic', 0.2, 0.1
  add_test 'float', 0.2, 0.1
  add_test 'float_no_hit', 0.1, 0.2
  add_test 'zero', 0.1, 0
  add_test 'zero_no_hit', 0, 1
end
