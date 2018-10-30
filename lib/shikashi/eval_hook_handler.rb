module Shikashi
  # EvalhookHandler extends EvalHook to add handlers for executable strings
  # (xstr), global variable assignment (gasgn) and access (gvar), constant read
  # (const) and assignment (cdecl) and method calls (method).
  #
  #
  class EvalhookHandler < EvalHook::HookHandler
    attr_accessor :sandbox

    def handle_xstr(str)
      source = get_caller

      privileges = sandbox.privileges[source]
      if privileges
        raise SecurityError, 'forbidden shell commands' unless privileges.xstr_allowed?
      end

      `#{str}`
    end

    def handle_gasgn(global_id, _value)
      source = get_caller

      privileges = sandbox.privileges[source]
      if privileges
        raise SecurityError, "Cannot assign global variable #{global_id}" unless privileges.global_write_allowed? global_id
      end

      nil
    end

    def handle_gvar(global_id)
      source = get_caller
      privileges = sandbox.privileges[source]
      if privileges
        raise SecurityError, "cannot access global variable #{global_id}" unless privileges.global_read_allowed? global_id
      end

      nil
    end

    def handle_const(name)
      source = get_caller
      privileges = sandbox.privileges[source]
      check_const_priv(name, privileges) if privileges
      get_const(name)
    end

    def handle_cdecl(klass, const_id, _value)
      source = get_caller

      privileges = sandbox.privileges[source]
      return unless privileges
      return if privileges.const_write_allowed?("#{klass}::#{const_id}")

      msg = "Cannot assign const #{klass}::#{const_id}"
      raise SecurityError, msg if klass != Object

      writable = privileges.const_write_allowed?(const_id.to_s)
      raise SecurityError, "Cannot assign const #{const_id}" unless writable
    end

    def handle_method(klass, recv, method_name)
      return if [:binding, :instance_eval, nil].include?(method_name)

      m = begin
            klass.instance_method(method_name)
          rescue StandardError
            method_name = :method_missing
            klass.instance_method(:method_missing)
          end

      source = get_caller
      dest_source = m.body.file
      return if source == dest_source

      msg = "Cannot invoke method #{method_name} on object of class #{klass}"
      raise SecurityError, msg unless sandbox.privileges[source]

      handle_loop(source, dest_source, klass, recv, method_name)
    end

    private

    def check_const_priv(name, privileges)
      constants = sandbox.base_namespace.constants
      name_is_a_constant = constants.any? { |c| name.to_sym == c.to_sym }
      msg = "cannot access constant #{name}"
      not_allowed = privileges.const_read_allowed?(name.to_s)
      raise SecurityError, msg unless name_is_a_constant || not_allowed
    end

    def get_const(name)
      const_value(sandbox.base_namespace.const_get(name))
    end

    def handle_loop(source, dest_source, klass, recv, method_name)
      privileges = sandbox.privileges[source]
      while privileges && (source != dest_source)
        msg = "Cannot invoke method #{method_name} on object of class #{klass}"
        can_loop = privileges.allow?(klass, recv, method_name, nil)
        raise SecurityError, msg unless can_loop

        source = sandbox.chain[source]
        privileges = sandbox.privileges[source] if dest_source
      end
    end

    def get_caller
      caller(3..3).first.split(':').first
    end
  end
end
