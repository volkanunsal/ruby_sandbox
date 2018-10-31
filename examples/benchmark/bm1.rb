  
require 'ruby_sandbox'
require 'benchmark'

code = "class X
		def foo(n)
		end
	end
	X.new.foo(1000)
	"

s = RubySandbox::Sandbox.new

Benchmark.bm(7) do |x|
  x.report('normal') do
    1000.times do
      s.run(code, RubySandbox::Whitelist.allow_method(:new))
    end
  end

  x.report('packet') do
    packet = s.packet(code, RubySandbox::Whitelist.allow_method(:new))
    1000.times do
      packet.run
    end
  end
end
