# "hello world" from within the sandbox

require 'rubygems'
require 'shikashi'

include Shikashi

priv = Shikashi::Privileges.allow_method(:print).allow_global_write(:$a)
Shikashi::Sandbox.run(priv,
                      '
                      $a = 9
                      print "assigned 9 to $a\n"
                      ')

p $a
