module RubySandbox
  #
  # Whitelist class provides methods to whitelist methods, classes
  # and class instances.
  #
  class Whitelist < Permissions
    def allowed?(klass, recv, method_name)
      on_method?(method_name) ||
        on_receiver?(recv, method_name) ||
        on_instance_of_klass?(klass, method_name) ||
        on_superclass_of_klass?(klass, method_name) ||
        on_instance_of_receiver_class?(recv, method_name)
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

    # TODO: test
    def check_rule(rule, method_name)
      rule && rule.allowed?(method_name)
    end

    # Define singleton methods using instance methods of this class.
    class << self
      im = (RubySandbox::Whitelist.instance_methods - Object.instance_methods)
      im.each do |mname|
        define_method(mname) do |*args|
          RubySandbox::Whitelist.new.send(mname, *args)
        end
      end
    end
  end
end
