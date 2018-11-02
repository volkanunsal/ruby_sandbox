module RubySandbox
  # Blacklist class provides methods to blacklist methods, classes
  # and class instances.
  class Blacklist < Permissions
    def allowed?(*args)
      blacklisted?(*args) == false
    end

    def blacklisted?(*opts)
      args = Argument.new(opts)
      method_name = args.pick_by_class(Symbol)
      # TODO: add check for instance methods of
      # TODO: add check for klass of
      # TODO: add check for instance
      rule_applies_to_method?(method_name)
    end

    alias deny_method add_method

    def safe!
      deny_method :eval
    end
  end
end