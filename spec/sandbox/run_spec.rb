require 'spec_helper'

include RubySandbox

$top_level_binding = binding
$VERBOSE = nil

describe 'Sandbox#run' do
  describe 'empty code (with and without privileges)' do
    [nil, Whitelist.new].each do |v|
      describe do
        let(:priv) { v }
        subject { -> { Sandbox.new.run '', priv } }
        it { is_expected.to_not raise_error }
      end
    end
  end

  describe 'non-empty code' do
    class X
      def foo; end
    end
    let(:code) { 'x.foo' }
    let(:action) { Sandbox.new.run(code, binding, opts) }
    let(:opts) { { privileges: priv, no_base_namespace: true } }
    subject { -> { action }}
    before  { x = X.new }

    describe 'without privileges' do
      let(:priv) { nil }
      it { is_expected.to raise_error(SecurityError) }
    end

    describe 'with privileges' do
      let(:priv) { Whitelist.new }
      before  do
        allow(priv).to receive(:allowed?).and_return(true)
      end
      it { is_expected.to raise_error(NoMethodError) }
    end
  end

  module ::A4
    module B4
      module C4
      end
    end
  end

  describe do
    let(:code) { '' }
    let(:s) { Sandbox.new }
    let(:priv) { Whitelist.new }
    let(:action) { s.run(code, priv, opts) }
    let(:opts) { {} }

    describe 'class declarations' do
      before do
        priv.allow_method :new
      end
      subject { action }
      let(:code) { "
        class ::TestInsideClass
          def foo
            1
          end
        end

        ::TestInsideClass.new.foo
      " }
      it { is_expected.to eq 1 }
    end

    describe 'use base namespace when the code uses colon3 node (2 levels)' do
      let(:code) { '::B4' }
      let(:opts) { { base_namespace: A4 } }
      let(:priv) { nil }
      subject { action }
      it { is_expected.to eq A4::B4 }
    end

    describe 'change base namespace when classes are declared (2 levels)' do
      let(:code) { "class ::X4
                 def foo
                  1
                 end
              end; ::X4.new.foo" }
      let(:opts) { { base_namespace: A4 } }
      let(:priv) { nil }
      subject { action }
      it { is_expected.to eq A4::X4.new.foo }
    end

    describe 'use base namespace when the code uses colon3 node (3 levels)' do
      let(:code) { '::C4' }
      let(:opts) { { binding: $top_level_binding, base_namespace: ::A4::B4 } }
      let(:priv) { nil }
      subject { action }
      it { is_expected.to eq ::A4::B4::C4 }
    end

    describe 'change base namespace when classes are declared (3 levels)' do
      let(:code) { "class ::X4
                 def foo
                  1
                 end
              end; ::X4.new.foo" }
      let(:opts) { { binding: $top_level_binding, base_namespace: ::A4::B4 } }
      let(:priv) { nil }
      subject { action }
      it { is_expected.to eq ::A4::B4::X4.new.foo }
    end

    describe 'change base namespace when classes are declared (3 levels)' do
      let(:code) { 'a' }
      let(:priv) { nil }
      subject do
        a = 5
        s.run(code, { binding: binding, no_base_namespace: true })
      end
      it { is_expected.to eq 5 }
    end

    describe 'instance variables' do
      class N
        def foo
          @a = 5
          Sandbox.new.run('@a', binding, no_base_namespace: true)
        end
      end
      let(:object) { N.new }
      subject { object.foo }
      it { is_expected.to eq 5 }
    end

    describe 'create a default module for each sandbox' do
      let(:code) { 'class X
               def foo
                  "foo inside sandbox"
               end
             end; X.new.foo' }
      let(:priv) { nil }
      subject { action }
      it { is_expected.to eq s.base_namespace::X.new.foo }
    end

    describe 'xstr' do
      let(:code) { '%x[echo hello world]' }
      subject { -> { action } }
      describe 'authorized' do
        before do
          priv.allow_xstr
        end
        it { is_expected.to_not raise_error }
      end

      describe 'not authorized' do
        it { is_expected.to raise_error(SecurityError) }
      end
    end

    describe 'global variable read' do
      let(:code) { '$a' }
      subject { -> { action } }

      describe 'not authorized' do
        it { is_expected.to raise_error(SecurityError) }
      end

      describe 'authorized' do
        before do
          priv.allow_global_read(:$a)
        end
        it { is_expected.to_not raise_error }
      end
    end

    describe 'constant read' do
      TESTCONSTANT9999 = 9999
      Fixnum::TESTCONSTANT9997 = 9997
      let(:code) { 'TESTCONSTANT9999' }

      describe 'not authorized' do
        subject { -> { action } }
        it { is_expected.to raise_error(SecurityError) }
      end

      describe 'authorized' do
        subject { action }
        before { priv.allow_const_read('TESTCONSTANT9999') }
        it { is_expected.to eq TESTCONSTANT9999 }

        describe 'nested' do
          let(:code) { 'Fixnum::TESTCONSTANT9997' }
          before do
            priv.allow_const_read('Fixnum')
          end
          it { is_expected.to eq Fixnum::TESTCONSTANT9997 }
        end
      end
    end

    describe 'global variable write' do
      let(:code) { '$a = 9' }
      subject { -> { action } }

      describe 'not authorized' do
        it { is_expected.to raise_error(SecurityError) }
      end

      describe 'authorized' do
        before do
          priv.allow_global_write(:$a)
        end
        it { is_expected.to_not raise_error }
        describe '$a' do
          subject { $a }
          it { is_expected.to eq 9 }
        end
      end
    end

    describe 'constant write' do
      let(:code) { 'TESTCONSTANT9999 = 99991' }

      describe 'not authorized' do
        subject { -> { action } }
        it { is_expected.to raise_error(SecurityError) }
      end

      describe 'authorized' do
        before do
          priv.allow_const_write('TESTCONSTANT9999')
        end
        subject { action }
        it { is_expected.to eq 99991 }

        describe TESTCONSTANT9999 do
          it { is_expected.to eq 99991 }
        end

        describe 'nested' do
          before do
            priv.allow_const_read('Fixnum')
            priv.allow_const_write('Fixnum::TESTCONSTANT9997')
          end
          let(:code) { 'Fixnum::TESTCONSTANT9997 = 99971' }
          describe Fixnum::TESTCONSTANT9997 do
            it { is_expected.to eq 99_971 }
          end
        end
      end
    end

    describe 'package' do
      let(:code) { 'print "hello world\n"' }
      let(:action) { s.packet('print "hello world\n"') }
      subject { -> { action } }
      it { is_expected.to_not raise_error }
    end
  end

  class ::XPackage
    def foo; end
  end

  [
    [['1'], [binding: binding]],
    [['1+1', { privileges: Whitelist.new.allow_method(:+) }], [binding: binding]]
  ].each do |args1, args2|
    describe 'allow and execute package of code' do
      begin
        sandbox_instance = Sandbox.new.run(*(args1 + args2))
      rescue Exception => e
        sandbox_error = e
      end

      begin
        packet_instance = Sandbox.new.packet(*args1).run(*args2)
      rescue Exception => e
        packet_error = e
      end

      describe 'sandbox_error' do
        subject { sandbox_error }
        it { is_expected.to eq packet_error }
      end

      describe 'sandbox_instance' do
        subject { sandbox_instance }
        it { is_expected.to eq packet_instance }
      end
    end
  end

  describe 'references to classes defined on previous run' do
    let(:code) { "class XinsideSandbox
        def foo
          1
        end
      end" }
    let(:s) { Sandbox.new }
    subject { s.run(code); s.run('XinsideSandbox') }
    it { is_expected.to eq s.base_namespace::XinsideSandbox }
  end

  describe 'method missing' do
    class OutsideX44
      def method_missing(name)
        name
      end
    end
    OutsideX44_ins = OutsideX44.new

    let(:s) { Sandbox.new }
    let(:priv) { Whitelist.new }
    before do
      priv.allow_const_read('OutsideX44_ins')
      priv.instances_of(OutsideX44).allow :method_missing
    end
    let(:code) { 'OutsideX44_ins.foo' }
    subject { s.run(code, priv) }
    it { is_expected.to eq :foo }
  end
end
