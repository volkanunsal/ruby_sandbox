module RubySandbox
  # Blacklist class provides methods to blacklist methods, classes
  # and class instances.
  class Blacklist < Permissions
    def allow?(*args)
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

    alias disallow_method add_method
    alias deny_method add_method

    def check_rule(rule, method_name)
      rule && rule.disallowed?(method_name)
    end

    def safe!
      disallow_method :eval
    end
  end
end
