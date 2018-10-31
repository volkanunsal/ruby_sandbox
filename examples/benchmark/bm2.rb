  
require 'ruby_sandbox'
require 'benchmark'

s = RubySandbox::Sandbox.new

class NilClass
  def foo; end
end

Benchmark.bm(7) do |x|
  x.report do
    code = "
		500000.times {
		nil.foo
		}
		"

    s.run code, RubySandbox::Whitelist.allow_method(:times).allow_method(:foo)
  end
end
