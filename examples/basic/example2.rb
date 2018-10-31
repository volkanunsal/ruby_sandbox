#
#
#
# Call external method from inside the sandbox
#
#
require 'ruby_sandbox'

def foo
  # privileged code, can do any operation
  print "foo\n"
end

s = RubySandbox.new
priv = RubySandbox.build(:whitelist)
priv.rule { allow_method(:print) }

s.run(priv, 'print "hello world\n"')
# => hello world
s.run(priv, 'do_evil_stuff')
# => SecurityError: Cannot invoke method do_evil_stuff on object of class Object