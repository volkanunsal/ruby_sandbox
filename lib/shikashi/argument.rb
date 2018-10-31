module Shikashi
  # Argument parses arguments to extract values by class or
  # hash key.
  #
  # Example 1: Pick by class.
  #
  #   args = [binding, :foo, :bar]
  #   args = Argument.new(args)
  #   value = args.pick(Binding, :binding)
  #   # => binding
  #
  # Example 2: Pick by hash key.
  #
  #   args = [{binding: binding, foo: 1}, :foo, :bar]
  #   args = Argument.new(args)
  #   value = args.pick(Binding, :binding)
  #   # => binding
  #
  # Example 3: Fallback to block.
  #
  #   args = [:foo, :bar]
  #   args = Argument.new(args)
  #   value = args.pick(Binding, :binding) { RubySandbox.global_binding }
  #   # => binding
  #
  # Error cases
  # ---------------
  #
  # Example 1: Ambiguous arguments
  #
  #   args = [{binding: binding}, binding]
  #   args = Argument.new(args)
  #   value = args.pick(Binding, :binding)
  #   # => ArgumentError: ambiguous parameters of class Binding and
  #   hash key binding.
  #
  class Argument
    attr_reader :args

    def initialize(args)
      @args = args
    end

    def pick(*opts)
      o = Argument.new(opts)

      klass = o.pick_by_class(Class)
      hash_key = o.pick_by_class(Symbol)

      ary = parse_args(hash_key, klass)

      if ary.size == 1
        ary.first
      elsif block_given?
        yield
      else
        raise_mandatory_arg_error(hash_key, klass)
      end
    end

    def pick_by_class(klass)
      klassary = args.select { |x| x.instance_of? klass }

      if klassary.size > 1
        raise_ambiguous_error(klass)
      elsif klassary.size == 1
        klassary.first
      end
    end

    private

    def parse_args(hash_key, klass)
      ary = []
      ary += parse_klass(klass) if klass
      ary += parse_hash_key(hash_key) if hash_key
      raise_ambiguous_error(klass, hash_key) if ary.size > 1
      ary
    end

    def parse_klass(klass)
      args.select { |x| x.instance_of?(klass) }
    end

    def parse_hash_key(hash_key)
      ary = []
      args.each do |x|
        next unless x.instance_of?(Hash)

        ary << x[hash_key] if x[hash_key]
      end
      ary
    end

    def raise_mandatory_arg_error(hash_key, klass)
      msg = "missing mandatory argument '#{hash_key}' or of class #{klass}"
      raise ArgumentError, msg
    end

    def raise_ambiguous_error(klass, hash_key = nil)
      a = [klass, hash_key].compact
      str = a.join(' and key ')
      msg = "ambiguous parameters of class #{str}"
      raise ArgumentError, msg
    end
  end
end
