# "hello world" from within the sandbox


require 'ruby_sandbox'

include RubySandbox

priv = RubySandbox::Whitelist.allow_method(:print).allow_global_write(:$a)
RubySandbox::Sandbox.run(priv,
                      '
                      $a = 9
                      print "assigned 9 to $a\n"
                      ')

p $a
