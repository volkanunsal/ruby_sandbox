require 'spec_helper'

include Shikashi

$top_level_binding = binding

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
        allow(priv).to receive(:allow?).and_return(true)
      end
      it { is_expected.to_not raise_error(SecurityError) }
    end
  end

  module ::A4
    module B4
      module C4
      end
    end
  end

  it 'should allow use a class declared inside' do
    priv = Whitelist.new
    priv.allow_method :new
    Sandbox.new.run("
      class ::TestInsideClass
        def foo
        end
      end

      ::TestInsideClass.new.foo
    ", priv)
  end

  it 'should use base namespace when the code uses colon3 node (2 levels)' do
    expect(Sandbox.new.run('::B4', base_namespace: A4)).to be == A4::B4
  end

  it 'should change base namespace when classes are declared (2 levels)' do
    code = "class ::X4
               def foo
               end
            end"
    Sandbox.new.run(code, base_namespace: A4)

    A4::X4
  end

  it 'should use base namespace when the code uses colon3 node (3 levels)' do
    expect(Sandbox.new.run('::C4',
                           $top_level_binding, base_namespace: ::A4::B4)).to be == ::A4::B4::C4
  end

  it 'should change base namespace when classes are declared (3 levels)' do
    code = "class ::X4
               def foo
               end
            end"
    Sandbox.new.run(code, $top_level_binding, base_namespace: ::A4::B4)
    A4::B4::X4
  end

  it 'should reach local variables when current binding is used' do
    a = 5
    expect(Sandbox.new.run('a', binding, no_base_namespace: true)).to be == 5
  end

  class N
    def foo
      @a = 5
      Sandbox.new.run('@a', binding, no_base_namespace: true)
    end
  end

  it 'should allow reference to instance variables' do
    expect(N.new.foo).to be == 5
  end

  it 'should create a default module for each sandbox' do
    s = Sandbox.new
    s.run('class X
             def foo
                "foo inside sandbox"
             end
           end')

    x = s.base_namespace::X.new
    expect(x.foo).to be == 'foo inside sandbox'
  end

  it 'should not allow xstr when no authorized' do
    s = Sandbox.new
    priv = Whitelist.new

    expect do
      s.run('%x[echo hello world]', priv)
    end.to raise_error(SecurityError)
  end

  it 'should allow xstr when authorized' do
    s = Sandbox.new
    priv = Whitelist.new

    priv.allow_xstr

    expect do
      s.run('%x[echo hello world]', priv)
    end.to_not raise_error
  end

  it 'should not allow global variable read' do
    s = Sandbox.new
    priv = Whitelist.new

    expect do
      s.run('$a', priv)
    end.to raise_error(SecurityError)
  end

  it 'should allow global variable read when authorized' do
    s = Sandbox.new
    priv = Whitelist.new

    priv.allow_global_read(:$a)

    expect do
      s.run('$a', priv)
    end.to_not raise_error
  end

  it 'should not allow constant variable read' do
    s = Sandbox.new
    priv = Whitelist.new

    TESTCONSTANT9999 = 9999
    expect do
      s.run('TESTCONSTANT9999', priv)
    end.to raise_error(SecurityError)
  end

  it 'should allow constant read when authorized' do
    s = Sandbox.new
    priv = Whitelist.new

    priv.allow_const_read('TESTCONSTANT9998')
    ::TESTCONSTANT9998 = 9998

    expect do
      expect(s.run('TESTCONSTANT9998', priv)).to be == 9998
    end.to_not raise_error
  end

  it 'should allow read constant nested on classes when authorized' do
    s = Sandbox.new
    priv = Whitelist.new

    priv.allow_const_read('Fixnum')
    Fixnum::TESTCONSTANT9997 = 9997

    expect do
      expect(s.run('Fixnum::TESTCONSTANT9997', priv)).to be == 9997
    end.to_not raise_error
  end

  it 'should not allow global variable write' do
    s = Sandbox.new
    priv = Whitelist.new

    expect do
      s.run('$a = 9', priv)
    end.to raise_error(SecurityError)
  end

  it 'should allow global variable write when authorized' do
    s = Sandbox.new
    priv = Whitelist.new

    priv.allow_global_write(:$a)

    expect do
      s.run('$a = 9', priv)
    end.to_not raise_error
  end

  it 'should not allow constant write' do
    s = Sandbox.new
    priv = Whitelist.new

    expect do
      s.run('TESTCONSTANT9999 = 99991', priv)
    end.to raise_error(SecurityError)
  end

  it 'should allow constant write when authorized' do
    s = Sandbox.new
    priv = Whitelist.new

    priv.allow_const_write('TESTCONSTANT9998')

    expect do
      s.run('TESTCONSTANT9998 = 99981', priv)
      expect(TESTCONSTANT9998).to be == 99_981
    end.to_not raise_error
  end

  it 'should allow write constant nested on classes when authorized' do
    s = Sandbox.new
    priv = Whitelist.new

    priv.allow_const_read('Fixnum')
    priv.allow_const_write('Fixnum::TESTCONSTANT9997')

    expect do
      s.run('Fixnum::TESTCONSTANT9997 = 99971', priv)
      expect(Fixnum::TESTCONSTANT9997).to be == 99_971
    end.to_not raise_error
  end

  it 'should allow package of code' do
    s = Sandbox.new

    expect do
      s.packet('print "hello world\n"')
    end.to_not raise_error
  end

  def self.package_oracle(args1, args2)
    it 'should allow and execute package of code' do
      e1 = nil
      e2 = nil
      r1 = nil
      r2 = nil

      begin
        s = Sandbox.new
        r1 = s.run(*(args1 + args2))
      rescue Exception => e
        e1 = e
      end

      begin
        s = Sandbox.new
        packet = s.packet(*args1)
        r2 = packet.run(*args2)
      rescue Exception => e
        e2 = e
      end

      expect(e1).to be == e2
      expect(r1).to be == r2
    end
  end

  class ::XPackage
    def foo; end
  end

  package_oracle ['1'], [binding: binding]
  package_oracle ['1+1', { privileges: Whitelist.allow_method(:+) }], [binding: binding]

  it 'should accept references to classes defined on previous run' do
    sandbox = Sandbox.new

    sandbox.run("class XinsideSandbox
    end")

    expect(sandbox.run('XinsideSandbox')).to be == sandbox.base_namespace::XinsideSandbox
  end

  class OutsideX44
    def method_missing(name)
      name
    end
  end
  OutsideX44_ins = OutsideX44.new

  it 'should allow method_missing handling' do
    sandbox = Sandbox.new
    privileges = Whitelist.new
    privileges.allow_const_read('OutsideX44_ins')
    privileges.instances_of(OutsideX44).allow :method_missing

    expect(sandbox.run('OutsideX44_ins.foo', privileges)).to be == :foo
  end
end
