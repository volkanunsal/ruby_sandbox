module Shikashi
  # Defines the permissions needed to declare classes within the sandbox
  #
  class Privileges
    def allow_class_definitions
      instances_of(Class).allow nil, :inherited, :method_added
      allow_method 'core#define_method'.to_sym
    end
  end
end
