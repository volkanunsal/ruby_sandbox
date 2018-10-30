require 'find'
require 'shikashi/allower'

module Shikashi
  # rubocop:disable Metrics/ClassLength
  #
  # The Privileges class represent permissions about methods and objects
  #
  class Privileges
    def initialize
      # Allowed
      @allowed_objects = {}
      @allowed_classes = {}
      @allowed_instances = {}
      @allowed_methods = []
      @allowed_klass_methods = {}
      @allowed_read_globals = []
      @allowed_read_consts = []
      @allowed_write_globals = []
      @allowed_write_consts = []
      # Disallowed
      @disallowed_methods = []
      @whitelist_mode = true
    end

    # TODO: test
    #
    # Specifies the mode in which to evaluate the permissions.
    #
    # Example 1:
    #   privileges.blacklist!
    #
    def blacklist!
      @whitelist_mode = false
    end

    # TODO: test
    #
    # Specifies the mode in which to evaluate the permissions.
    #
    # Example 1:
    #   privileges.whitelist!
    #
    def whitelist!
      @whitelist_mode = true
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

    # allow the execution of method named method_name wherever
    #
    # Example:
    #   privileges.allow_method(:foo)
    #
    def allow_method(method_name)
      @allowed_methods << method_name.to_sym
      self
    end

    # disallow the execution of method named method_name wherever
    #
    # Example:
    #   privileges.disallow_method(:foo)
    #
    def disallow_method(method_name)
      @disallowed_methods << method_name.to_sym
      self
    end

    def allow?(klass, recv, method_name, method_id)
      if whitelist_mode?
        whitelisted?(klass, recv, method_name, method_id)
      else
        !blacklisted?(klass, recv, method_name, method_id)
      end
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

    class << self
      (Shikashi::Privileges.instance_methods - Object.instance_methods).each do |mname|
        define_method(mname) do |*args|
          Shikashi::Privileges.new.send(mname, *args)
        end
      end
    end

    def self.load_privilege_packages
      Find.find(__FILE__.split('/')[0..-2].join('/') + '/privileges') do |path|
        require path if path =~ /\.rb$/
      end
    end

    load_privilege_packages

    private

    def whitelist_mode?
      @whitelist_mode
    end

    def blacklisted?(_klass, _recv, method_name, _method_id)
      # TODO: add check for instance methods of
      # TODO: add check for klass of
      # TODO: add check for instance
      disallows_method?(method_name)
    end

    def whitelisted?(klass, recv, method_name, _method_id)
      allows_method?(method_name) ||
        allows_method_on_obj?(recv, method_name) ||
        allows_instance_methods_of?(klass, method_name) ||
        allows_klass_or_superclasses_of?(klass, method_name) ||
        allows_instance_of?(recv, method_name)
    rescue StandardError => e
      print "ERROR: #{e}\n"
      print e.backtrace.join("\n")
      false
    end

    def allows_method?(method_name)
      @allowed_methods.include?(method_name)
    end

    def disallows_method?(method_name)
      @disallowed_methods.include?(method_name)
    end

    def allows_method_on_obj?(recv, method_name)
      id = recv.object_id
      allower = @allowed_objects[id]
      check_allower(allower, method_name)
    end

    def allows_instance_methods_of?(klass, method_name)
      # Find method in the instance methods of class.
      method = klass.instance_method(method_name) if method_name
      # Not found. Return nil.
      return unless method

      # Check if method's owner, i.e. class, is in allowed
      # klass methods
      allower = @allowed_klass_methods[method.owner.object_id]
      check_allower(allower, method_name)
    end

    # TODO: test
    #
    # Is this supposed to receive a klass or a receiver?
    #
    def allows_klass_or_superclasses_of?(klass, method_name)
      return unless klass.instance_of?(Class)

      loop do
        return true if allows_klass_of?(klass, method_name)
        break if klass.nil? || klass == Object

        klass = klass.superclass
      end
    end

    def allows_klass_of?(klass, method_name)
      allower = @allowed_classes[klass.object_id]
      check_allower(allower, method_name)
    end

    def allows_instance_of?(recv, method_name)
      allower = @allowed_instances[recv.class.object_id]
      check_allower(allower, method_name)
    end

    def check_allower(allower, method_name)
      return unless allower && allower.allowed?(method_name)

      @last_allowed = allower
      true
    end

    def build_allower(hash, key)
      allower = hash[key]
      unless allower
        allower = Allower.new(self)
        hash[key] = allower
      end
      allower
    end
  end
  # rubocop:enable Metrics/ClassLength
end
