require 'spec_helper'

include RubySandbox

describe 'Blacklist' do
  describe '#deny_method' do
    let(:method_name) { :to_s }
    subject { Blacklist.new.deny_method(method_name) }
    it { is_expected.to_not be_allow(Fixnum, 4, method_name) }
  end

  describe '#safe!' do
    subject { Blacklist.new.safe! }
    it { is_expected.to_not be_allow(Kernel, Object, :eval) }
  end
end
