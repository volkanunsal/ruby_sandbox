#
#
#
# Call method defined in sandbox from outside
#
#
#
require 'ruby_sandbox'

s = RubySandbox.new
priv = RubySandbox.build(:whitelist)

obj = self

# Allow execution of :foo and :puts in this object
priv.rule do
  object(obj)
    .allow(:foo)
    .allow(:puts)
end

# Inside the sandbox, only can use method foo on main and method times on instances of Fixnum
code = "
def inside_foo(a)
	puts 'inside_foo'
	if (a)
	system('ls -l') # denied
	end
end
"

s.run(code, priv, no_base_namespace: true)

inside_foo(false)

