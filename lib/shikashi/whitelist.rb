module Shikashi
  # Whitelist class provides methods to whitelist methods, classes
  # and class instances.
  class Whitelist < Permissions
    def initialize
      super
      @allowed_objects = {}
      @allowed_classes = {}
      @allowed_instances = {}
      @allowed_methods = []
      @allowed_klass_methods = {}
    end

    def allow?(klass, recv, method_name)
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

    # Define the permissions needed to define singleton methods.
    def allow_singleton_methods
      allow_method :singleton_method_added
      allow_method 'core#define_singleton_method'.to_sym
    end

    # Define the permissions needed to raise exceptions
    def allow_exceptions
      allow_method :raise
      methods_of(Exception).allow :backtrace, :set_backtrace, :exception
    end

    # Defines the permissions needed to declare classes within the sandbox
    def allow_class_definitions
      instances_of(Class).allow nil, :inherited, :method_added
      allow_method 'core#define_method'.to_sym
    end

    def allows_method?(method_name)
      @allowed_methods.include?(method_name)
    end

    def allows_method_on_obj?(recv, method_name)
      id = recv.object_id
      rule = @allowed_objects[id]
      check_rule(rule, method_name)
    end

    def allows_instance_methods_of?(klass, method_name)
      # Find method in the instance methods of class.
      method = klass.instance_method(method_name) if method_name
      # Not found. Return nil.
      return unless method

      # Check if method's owner, i.e. class, is in allowed
      # klass methods
      rule = @allowed_klass_methods[method.owner.object_id]
      check_rule(rule, method_name)
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
      rule = @allowed_classes[klass.object_id]
      check_rule(rule, method_name)
    end

    def allows_instance_of?(recv, method_name)
      rule = @allowed_instances[recv.class.object_id]
      check_rule(rule, method_name)
    end

    def check_rule(rule, method_name)
      rule && rule.allowed?(method_name)
    end

    # Define singleton methods using instance methods of this class.
    class << self
      im = (Shikashi::Whitelist.instance_methods - Object.instance_methods)
      im.each do |mname|
        define_method(mname) do |*args|
          Shikashi::Whitelist.new.send(mname, *args)
        end
      end
    end
  end
end
