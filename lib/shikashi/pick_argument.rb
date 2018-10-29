module Arguments
  module NoDefault
  end
end

class Array
  def pick_by_class(klass)
    klassary = self.select{|x| x.instance_of? klass}
    if klassary.size > 1
      raise ArgumentError, "ambiguous parameters of class #{klass}"
    elsif klassary.size == 1
      klassary.first
    else
      nil
    end
  end

  def pick(*args)

    klass = args.pick_by_class Class
    hash_key = args.pick_by_class Symbol

    ary = []

    if klass
      ary = self.select{|x| x.instance_of? klass}

      if ary.size > 1
        raise ArgumentError, "ambiguous parameters of class #{klass}"
      end
    else
      ary = []
    end

    if hash_key
      each do |x|
        if x.instance_of? Hash
          if x[hash_key]
            ary << x[hash_key]
          end
        end
      end

      if ary.size > 1
        raise ArgumentError, "ambiguous parameters of class #{klass} and key '#{hash_key}'"
      end

    end

    if ary.size == 1
      return ary.first
    end

    unless block_given?
      raise ArgumentError, "missing mandatory argument '#{hash_key}' or of class #{klass}"
    end

    yield
  end
end