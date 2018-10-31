# "hello world" from within the sandbox


require 'ruby_sandbox'

s = RubySandbox::Sandbox.new
priv = RubySandbox::Whitelist.new
priv.allow_method :print

s.run(priv, 'print "hello world\n"')
