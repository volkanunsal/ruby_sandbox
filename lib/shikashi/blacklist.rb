module Shikashi
  # Privileges class provides methods to whitelist methods, classes
  # and class instances.
  class Blacklist < PrivilegesBase
    def initialize
      super
      @disallowed_methods = []
    end

    def allow?(klass, recv, method_name)
      !blacklisted?(klass, recv, method_name)
    end

    def blacklisted?(_klass, _recv, method_name)
      # TODO: add check for instance methods of
      # TODO: add check for klass of
      # TODO: add check for instance
      disallows_method?(method_name)
    end

    def disallows_method?(method_name)
      @disallowed_methods.include?(method_name)
    end
  end
end
