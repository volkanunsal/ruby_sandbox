require 'rubygems'
require 'shikashi'
require 'benchmark'

s = Shikashi::Sandbox.new

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

    s.run code, Shikashi::Whitelist.allow_method(:times).allow_method(:foo)
  end
end
