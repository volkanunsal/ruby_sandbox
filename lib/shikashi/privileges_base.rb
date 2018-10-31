require 'find'
require 'shikashi/allower'

module Shikashi
  #
  # The PrivilegesBase class represent permissions about methods and objects
  #
  class PrivilegesBase
    def initialize
      @allowed_read_globals = []
      @allowed_read_consts = []
      @allowed_write_globals = []
      @allowed_write_consts = []
    end

    def allow?(*)
      true
    end

    def xstr_allowed?
      @xstr_allowed
    end

    def global_read_allowed?(varname)
      @allowed_read_globals.include? varname
    end

    def global_write_allowed?(varname)
      @allowed_write_globals.include? varname
    end

    def const_read_allowed?(varname)
      @allowed_read_consts.include? varname
    end

    def const_write_allowed?(varname)
      @allowed_write_consts.include? varname
    end

    # Enables the permissions needed to execute system calls from the script
    #
    # Example:
    #
    #   s = Sandbox.new
    #   priv = Privileges.new
    #
    #   priv.allow_xstr
    #
    #   s.run(priv, '
    #     %x[ls -l]
    #   ')
    #
    #
    # Example 2:
    #
    #   Sandbox.run('%x[ls -l]', Privileges.allow_xstr)
    #
    def allow_xstr
      @xstr_allowed = true

      self
    end

    # Enables the permissions needed to read one or more global variables
    #
    # Example:
    #
    #   s = Sandbox.new
    #   priv = Privileges.new
    #
    #   priv.allow_method :print
    #   priv.allow_global_read :$a
    #
    #   $a = 9
    #
    #   s.run(priv, '
    #   print "$a value:", $a, "s\n"
    #   ')
    #
    # Example 2
    #
    #   Sandbox.run('
    #   print "$a value:", $a, "s\n"
    #   print "$b value:", $b, "s\n"
    #   ', Privileges.allow_global_read(:$a,:$b) )
    #
    def allow_global_read(*varnames)
      varnames.each do |varname|
        @allowed_read_globals << varname.to_sym
      end

      self
    end

    # Enables the permissions needed to create or change one or more global variables
    #
    # Example:
    #
    #   s = Sandbox.new
    #   priv = Privileges.new
    #
    #   priv.allow_method :print
    #   priv.allow_global_write :$a
    #
    #   s.run(priv, '
    #   $a = 9
    #   print "assigned 9 to $a\n"
    #   ')
    #
    #   p $a
    #
    def allow_global_write(*varnames)
      varnames.each do |varname|
        @allowed_write_globals << varname.to_sym
      end

      self
    end

    # Enables the permissions needed to create or change one or more constants
    #
    # Example:
    #   s = Sandbox.new
    #   priv = Privileges.new
    #
    #   priv.allow_method :print
    #   priv.allow_const_write "Object::A"
    #
    #   s.run(priv, '
    #   print "assigned 8 to Object::A\n"
    #   A = 8
    #   ')
    #
    #   p A
    def allow_const_write(*varnames)
      varnames.each do |varname|
        @allowed_write_consts << varname.to_s
      end
      self
    end

    # Enables the permissions needed to read one or more constants
    #
    # Example:
    #   s = Sandbox.new
    #   priv = Privileges.new
    #
    #   priv.allow_method :print
    #   priv.allow_const_read "Object::A"
    #
    #   A = 8
    #   s.run(priv, '
    #   print "assigned Object::A:", A,"\n"
    #   ')
    #
    def allow_const_read(*varnames)
      varnames.each do |varname|
        @allowed_read_consts << varname.to_s
      end

      self
    end

    # Specifies the methods allowed for an specific object
    #
    # Example 1:
    #   privileges.object(Hash).allow :new
    #
    def object(obj)
      build_allower(@allowed_objects, obj.object_id)
    end

    #
    # Specifies the methods allowed for the instances of a class
    #
    # Examples:
    #   # allow calls of methods named "each" over instances of Array
    #   privileges.instances_of(Array).allow :each
    #
    #   # allow calls of methods named "each" and "map" over instances of Array
    #   privileges.instances_of(Array).allow :select, map
    #
    #   # allow any method call over instances of Hash
    #   privileges.instances_of(Hash).allow_all
    #
    def instances_of(klass)
      build_allower(@allowed_instances, klass.object_id)
    end

    #
    # Specifies the methods allowed for an implementation in specific class
    #
    # Example 1:
    #   privileges.methods_of(X).allow :foo
    #
    # ...
    # class X
    #   def foo # allowed :)
    #   end
    # end
    #
    # class Y < X
    #   def foo # disallowed
    #   end
    # end
    #
    # X.new.foo # allowed
    # Y.new.foo # disallowed: SecurityError
    # ...
    #
    def methods_of(klass)
      build_allower(@allowed_klass_methods, klass.object_id)
    end

    private

    def build_allower(hash, key)
      allower = hash[key]
      unless allower
        allower = Allower.new(self)
        hash[key] = allower
      end
      allower
    end
  end
end
