module Shikashi
  # Used in Whitelist to store information about specified method permissions
  class Rule
    def initialize(privileges = nil)
      @privileges = privileges
      @rule = []
      @disrule = []
      @num_rules = 0
      @all = false
      @none = false
    end

    # --------------- PREDICATES ----------------------
    #
    # return true if the method named method_name is allowed
    # Example
    #
    # rule = Rule.new
    # rule.allowed? :foo # => false
    # rule.allow :foo
    # rule.allowed? :foo # => true
    # rule.allow_all
    # rule.allowed? :bar # => true
    #
    # Whitelist#instance_of, Whitelist#methods_of and Whitelist#object returns the corresponding
    # instance of Rule
    def allowed?(method_name)
      @all || @rule.include?(method_name)
    end

    # return true if the method named method_name is disallowed
    # Example
    #
    # rule = Rule.new
    # rule.disallowed? :foo # => false
    # rule.disallow :foo
    # rule.disallowed? :foo # => true
    # rule.disallow_all
    # rule.disallowed? :bar # => true
    #
    # Whitelist#instance_of, Whitelist#methods_of and Whitelist#object returns the corresponding
    # instance of Rule
    def disallowed?(method_name)
      @none || @disrule.include?(method_name)
    end

    # --------------- ACTIONS ----------------------

    # Specifies that a method or list of methods are allowed
    # Example
    #
    # rule = Rule.new
    # rule.allow :foo
    # rule.allow :foo, :bar
    # rule.allow :foo, :bar, :test
    #
    def allow(*method_names)
      method_names.each do |mn|
        @rule << mn
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
    # rule = Rule.new
    # rule.disallow :foo
    # rule.disallow :foo, :bar
    # rule.disallow :foo, :bar, :test
    #
    def disallow(*method_names)
      method_names.each do |mn|
        @disrule << mn
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

    attr_reader :num_rules

    private

    def tick
      @num_rules += 1
    end
  end
end
