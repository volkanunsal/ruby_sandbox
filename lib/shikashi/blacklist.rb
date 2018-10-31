module Shikashi
  # Blacklist class provides methods to blacklist methods, classes
  # and class instances.
  class Blacklist < Permissions
    def allow?(klass, recv, method_name)
      blacklisted?(klass, recv, method_name) == false
    end

    def blacklisted?(_klass, _recv, method_name)
      # TODO: add check for instance methods of
      # TODO: add check for klass of
      # TODO: add check for instance
      rule_applies_to_method?(method_name)
    end

    alias disallow_method add_method

    def check_rule(rule, method_name)
      rule && rule.disallowed?(method_name)
    end

    def safe!
      disallow_method :eval
    end
  end
end
