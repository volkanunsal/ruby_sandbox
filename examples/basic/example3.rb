# define a class outside the sandbox and use it in the sandbox


require 'shikashi'

s = Shikashi::Sandbox.new

class ShikaX
  def foo
    print "ShikaX#foo\n"
  end

  def bar
    system('echo hello world') # accepted, called from privileged context
  end

  def privileged_operation(out)
    # write to file specified in out
    system('echo privileged operation > ' + out)
  end
end

priv = Shikashi::Whitelist
       .allow_method(:print) # allow execution of print
       .object(ShikaX).allow(:new) # allow method new of class ShikaX
       .instances_of(ShikaX).allow(:foo, :bar) # allow instance methods of ShikaX. Note that the method privileged_operations is not allowed
       .allow_const_read('ShikaX', 'Shikashi::SecurityError') # allow the access of ShikaX constant

# inside the sandbox, only can use method foo on main and method times on instances of Fixnum
s.run(priv, '
x = ShikaX.new
x.foo
x.bar
')

# begin
# x.privileged_operation # FAIL
# rescue SecurityError
# print "privileged_operation failed due security error\n"
# end
