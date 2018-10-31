module Shikashi
  #
  # Whitelist class provides methods to whitelist methods, classes
  # and class instances.
  #
  class Whitelist < Permissions
    def allow?(klass, recv, method_name)
      rule_applies_to_method?(method_name) ||
        rule_applies_to_method_on_obj?(recv, method_name) ||
        rule_applies_to_instance_methods_of?(klass, method_name) ||
        rule_applies_to_klass_or_superclasses_of?(klass, method_name) ||
        rule_applies_to_instance_of?(recv, method_name)
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
    alias allow_method add_method

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
