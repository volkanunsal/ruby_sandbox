module RubySandbox
  # rubocop:disable_line Style/Documentation
  module RuleHelpers
    protected

    def on_method?(method_name)
      @methods.include?(method_name)
    end

    def on_receiver?(recv, method_name)
      id = recv.object_id
      rule = @objects[id]
      check_rule(rule, method_name)
    end

    def on_instance_of_klass?(klass, method_name)
      # Find method in the instance methods of class.
      method = klass.instance_method(method_name) if method_name
      # Not found. Return nil.
      return unless method

      # Check if method's owner, i.e. class, is in allowed
      # klass methods
      rule = @klass_methods[method.owner.object_id]
      check_rule(rule, method_name)
    end

    # TODO: test
    def on_ancestor_chain_of_klass?(klass, method_name)
      return unless klass.instance_of?(Class)

      loop do
        return true if on_klass_of?(klass, method_name)
        break if klass.nil? || klass == Object

        klass = klass.superclass
      end
    end

    def on_klass_of?(klass, method_name)
      rule = @classes[klass.object_id]
      check_rule(rule, method_name)
    end

    def on_instance_of_receiver_class?(recv, method_name)
      rule = @instances[recv.class.object_id]
      check_rule(rule, method_name)
    end

    private

    def num_rules
      this = self

      instance_variables.inject(0) do |s, v|
        rs = this.instance_variable_get(v)
        count = proc { |rule|
          case rule
          when Symbol
            s += 1
          else
            s = rule.num_rules + s
          end
        }

        case rs
        when Hash
          rs.each_value(&count)
        when Array
          rs.each(&count)
        end

        s
      end
    end

    def build_rule(hash, key)
      rule = hash[key]
      unless rule
        rule = Rule.new(self)
        hash[key] = rule
      end
      rule
    end
  end
end
