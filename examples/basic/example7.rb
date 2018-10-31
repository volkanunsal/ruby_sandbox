require 'ruby_sandbox'

priv = RubySandbox::Whitelist
       .allow_method(:print)
       .allow_const_write('Object::A')

RubySandbox::Sandbox.run(priv, '
print "assigned 8 to Object::A\n"
A = 8
')
p A
