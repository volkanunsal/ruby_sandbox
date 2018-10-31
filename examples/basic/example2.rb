# call external method from inside the sandbox


require 'ruby_sandbox'

def foo
  # privileged code, can do any operation
  print "foo\n"
end

s = RubySandbox::Sandbox.new
priv = RubySandbox::Whitelist.new

# allow execution of foo in this object
priv.object(self).allow :foo

# allow execution of method :times on instances of Fixnum
priv.instances_of(Fixnum).allow :times

# inside the sandbox, only can use method foo on main and method times on instances of Fixnum
s.run(priv, '2.times do foo end', no_base_namespace: true)
