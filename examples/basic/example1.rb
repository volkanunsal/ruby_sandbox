# "hello world" from within the sandbox

require 'rubygems'
require 'shikashi'

s = Shikashi::Sandbox.new
priv = Shikashi::Whitelist.new
priv.allow_method :print

s.run(priv, 'print "hello world\n"')
