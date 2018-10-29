module Shikashi
  class Privileges
    #Define the permissions needed to define singleton methods within the sandbox
    def allow_singleton_methods
      allow_method :singleton_method_added
      allow_method "core#define_singleton_method".to_sym
    end
  end
end
