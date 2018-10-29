# call method defined in sandbox from outside
require "rubygems"
require "shikashi"

s = Shikashi::Sandbox.new
priv = Shikashi::Privileges.new

# allow execution of foo in this object
priv.object(self).allow :foo

# allow execution of puts in this object
priv.object(self).allow :puts

#inside the sandbox, only can use method foo on main and method times on instances of Fixnum
code = "
def inside_foo(a)
	puts 'inside_foo'
	if (a)
	system('ls -l') # denied
	end
end
"

s.run(code, priv, :no_base_namespace => true)

inside_foo(false)
inside_foo(true) #SecurityError
