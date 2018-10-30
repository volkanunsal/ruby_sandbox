require 'rubygems'
require 'shikashi'

priv = Shikashi::Privileges
       .allow_method(:print)
       .allow_const_write('Object::A')

Shikashi::Sandbox.run(priv, '
print "assigned 8 to Object::A\n"
A = 8
')
p A
