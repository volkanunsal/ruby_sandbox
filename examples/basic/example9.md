### Example 2

Call external method from inside the sandbox

```ruby
  def foo
    # privileged code, can do any operation
    print "foo\n"
  end

  s = RubySandbox.new
  priv = RubySandbox.build(:whitelist)

  # allow execution of foo in this object
  priv.rule { object(self).allow :foo }

  # allow execution of method :times on instances of Fixnum
  priv.rule { instances_of(Fixnum).allow(:times) }

  #inside the sandbox, only can use method foo on main and method times on instances of Fixnum
  s.run(priv, "2.times do foo end", no_base_namespace: true)
```

### Example 3

Define a class outside the sandbox and use it in the sandbox

```ruby
  s = RubySandbox.new
  priv = RubySandbox.build(:whitelist)

  # allow execution of print
  priv.allow_method :print

  class X
    def foo
      print "X#foo\n"
    end

    def bar
      system("echo hello world") # accepted, called from privileged context
    end

    def privileged_operation( out )
      # write to file specified in out
      system("echo privileged operation > " + out)
    end
  end
  # allow method new of class X
  priv.object(X).allow :new

  # allow instance methods of X. Note that the method privileged_operations is not allowed
  priv.instances_of(X).allow :foo, :bar

  priv.allow_method :=== # for exception handling
  #inside the sandbox, only can use method foo on main and method times on instances of Fixnum
  s.run(priv, '
  x = X.new
  x.foo
  x.bar

  begin
  x.privileged_operation # FAIL
  rescue SecurityError
  print "privileged_operation failed due security error\n"
  end
  ')
```

### Example 4

define a class from inside the sandbox and use it from outside

```ruby
  s = RubySandbox.new
  priv = RubySandbox.build(:whitelist)

  # allow execution of print
  priv.allow_method :print

  #inside the sandbox, only can use method foo on main and method times on instances of Fixnum
  s.run(priv, '
  class X
    def foo
      print "X#foo\n"
    end

    def bar
      system("ls -l")
    end
  end
  ')

  x = s.base_namespace::X.new
  x.foo
  begin
    x.bar
  rescue SecurityError => e
    print "x.bar failed due security errors: #{e}\n"
  end
```

### Base namespace

```ruby
  class X
    def foo
      print "X#foo\n"
    end
  end

  s = RubySandbox.new

  s.run( "
    class X
    def foo
      print \"foo defined inside the sandbox\\n\"
    end
    end
    ", Privileges.allow_method(:print))


  x = X.new # X class is not affected by the sandbox (The X Class defined in the sandbox is SandboxModule::X)
  x.foo

  x = s.base_namespace::X.new
  x.foo

  s.run("X.new.foo", Privileges.allow_method(:new).allow_method(:foo))
```

### Timeout example

```ruby
  s = RubySandbox.new
  perm = RubySandbox.build(:whitelist)

  perm.allow_method :sleep

  s.run(perm,"sleep 3", :timeout => 2) # raise RubySandbox::Timeout::Error after 2 seconds
```
