require 'shikashi'

priv = Shikashi::Whitelist
       .allow_method(:print)
       .allow_const_write('Object::A')

Shikashi::Sandbox.run(priv, '
print "assigned 8 to Object::A\n"
A = 8
')
p A
