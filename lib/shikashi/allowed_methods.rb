module Shikashi
  # Used in Privileges to store information about specified method permissions
  class AllowedMethods
    def initialize(privileges = nil)
      @privileges = privileges
      @allowed_methods = []
      @redirect_hash = {}
      @all = false
    end

    # return true if the method named method_name is allowed
    # Example
    #
    # allowed_methods = AllowedMethods.new
    # allowed_methods.allowed? :foo # => false
    # allowed_methods.allow :foo
    # allowed_methods.allowed? :foo # => true
    # allowed_methods.allow_all
    # allowed_methods.allowed? :bar # => true
    #
    # Privileges#instance_of, Privileges#methods_of and Privileges#object returns the corresponding
    # instance of AllowedMethods
    def allowed?(method_name)
      if @all
        true
      else
        @allowed_methods.include?(method_name)
      end
    end

    # Specifies that a method or list of methods are allowed
    # Example
    #
    # allowed_methods = AllowedMethods.new
    # allowed_methods.allow :foo
    # allowed_methods.allow :foo, :bar
    # allowed_methods.allow :foo, :bar, :test
    #
    def allow(*method_names)
      method_names.each do |mn|
        @allowed_methods << mn
      end

      @privileges
    end

    # Specifies that any method is allowed
    def allow_all
      @all = true

      @privileges
    end
  end
end
