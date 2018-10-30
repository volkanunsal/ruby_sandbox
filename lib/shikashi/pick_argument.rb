#
# Monkey patch Array class to add 2 utlity methods
#
class Array
  def pick_by_class(klass)
    klassary = select { |x| x.instance_of? klass }
    raise ArgumentError, "ambiguous parameters of class #{klass}" if klassary.size > 1

    klassary.first if klassary.size == 1
  end

  # rubocop:disable Metrics/AbcSize:
  def pick(*args)
    klass = args.pick_by_class Class
    hash_key = args.pick_by_class Symbol

    ary = []

    if klass
      ary = select { |x| x.instance_of? klass }
      msg = "ambiguous parameters of class #{klass}"
      raise ArgumentError, msg if ary.size > 1
    end

    if hash_key
      each do |x|
        next unless x.instance_of? Hash

        ary << x[hash_key] if x[hash_key]
      end
      msg = "ambiguous parameters of class #{klass} and key '#{hash_key}'"
      raise ArgumentError, msg if ary.size > 1
    end

    return ary.first if ary.size == 1

    msg = "missing mandatory argument '#{hash_key}' or of class #{klass}"
    raise ArgumentError, msg unless block_given?

    yield
  end
  # rubocop:enable Metrics/AbcSize:
end
