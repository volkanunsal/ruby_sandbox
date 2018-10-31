module Shikashi
  # Used in Whitelist to store information about specified method permissions
  class Allower
    def initialize(privileges = nil)
      @privileges = privileges
      @allower = []
      @disallower = []
      @num_rules = 0
      @all = false
      @none = false
    end

    # --------------- PREDICATES ----------------------
    #
    # return true if the method named method_name is allowed
    # Example
    #
    # allower = Allower.new
    # allower.allowed? :foo # => false
    # allower.allow :foo
    # allower.allowed? :foo # => true
    # allower.allow_all
    # allower.allowed? :bar # => true
    #
    # Whitelist#instance_of, Whitelist#methods_of and Whitelist#object returns the corresponding
    # instance of Allower
    def allowed?(method_name)
      @all || @allower.include?(method_name)
    end

    # return true if the method named method_name is disallowed
    # Example
    #
    # allower = Allower.new
    # allower.disallowed? :foo # => false
    # allower.disallow :foo
    # allower.disallowed? :foo # => true
    # allower.disallow_all
    # allower.disallowed? :bar # => true
    #
    # Whitelist#instance_of, Whitelist#methods_of and Whitelist#object returns the corresponding
    # instance of Allower
    def disallowed?(method_name)
      @none || @disallower.include?(method_name)
    end


    # --------------- ACTIONS ----------------------

    # Specifies that a method or list of methods are allowed
    # Example
    #
    # allower = Allower.new
    # allower.allow :foo
    # allower.allow :foo, :bar
    # allower.allow :foo, :bar, :test
    #
    def allow(*method_names)
      method_names.each do |mn|
        @allower << mn
      end
      tick
      @privileges
    end

    # Specifies that any method is allowed
    def allow_all
      @all = true
      tick
      @privileges
    end

    # Specifies that a method or list of methods are disallowed
    # Example
    #
    # allower = Allower.new
    # allower.disallow :foo
    # allower.disallow :foo, :bar
    # allower.disallow :foo, :bar, :test
    #
    def disallow(*method_names)
      method_names.each do |mn|
        @disallower << mn
      end
      tick
      @privileges
    end

    # Specifies that all methods are disallowed
    def disallow_all
      @none = true
      tick
      @privileges
    end

    def num_rules
      @num_rules
    end

    private

    def tick
      @num_rules += 1
    end
  end
end
