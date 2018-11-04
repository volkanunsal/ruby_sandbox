require 'evalhook'
require 'timeout'
require 'securerandom'
require 'ruby_sandbox/getsource'
require 'ruby_sandbox/eval_hook_handler'
require 'ruby_sandbox/packet'

# RubySandbox is the module namespace
module RubySandbox
  class << self
    attr_accessor :global_binding
  end

  # raised when reach the timeout in a script execution restricted by timeout (see Sandbox#run)
  class TimeoutError < RuntimeError
  end

  # rubocop:disable Metrics/ClassLength
  # The sandbox class runs the sandbox. Only one instance of sandbox can be defined
  # per thread (each thread may have its own sandbox running.)
  #
  #= Example
  #
  # s = Sandbox.new
  # priv = Whitelist.new
  # priv.allow_method :print
  #
  # s.run(priv, 'print "hello world\n"')
  class Sandbox
    attr_reader :privileges, :base_namespace, :hook_handler, :chain

    def initialize
      # Privileges of restricted code, indexed by source file location.
      @privileges                  = {}
      @hook_handler_list           = []
      @chain                       = {}
      @hook_handler                = instantiate_evalhook_handler
      @hook_handler.sandbox        = self
      @base_namespace              = create_adhoc_base_namespace
      @hook_handler.base_namespace = @base_namespace
    end

    # Run the code in sandbox with the given privileges
    #
    # Example:
    #
    #   sandbox = Sandbox.new
    #   privileges = Whitelist.new
    #   privileges.allow_method :print
    #   sandbox.run('print "hello world\n"', privileges)
    #
    def run(*args)
      opts = Argument.new(args)
      t = build_timeout(opts)
      b = build_binding(opts)
      code, source = process_args(*args)

      Timeout.timeout(t) do
        hook_handler.evalhook(code, b, source)
      end
    rescue Timeout::Error
      raise RubySandbox::TimeoutError
    end

    def build_timeout(opts)
      t = opts.pick(:timeout) { nil }
      raise ArgumentError, 'timeout cannot be zero.' if t == 0

      t || 0
    end

    def build_binding(opts)
      opts.pick(Binding, :binding) { RubySandbox.global_binding }
    end

    def wrap_code(code)
      base_ns = @hook_handler.base_namespace
      is_module = eval(base_ns.to_s).instance_of? Module
      if is_module
        "module #{base_ns}\n #{code}\n end\n"
      else
        "class #{base_ns}\n #{code}\n end\n"
      end
    end

    # Creates a packet of code with the given privileges to execute later.
    def packet(*args)
      code, source, privileges_ = process_args(*args)
      evalhook_packet = @hook_handler.packet(code)
      RubySandbox::Packet.new(evalhook_packet, privileges_, source)
    end

    class Opts
      attr_reader :privileges,
                  :code,
                  :base_namespace,
                  :no_base_namespace,
                  :encoding,
                  :source

      def initialize(*args)
        opts                = Argument.new(args)
        @privileges         = opts.pick(Permissions, :privileges) { Whitelist.new }
        @code               = opts.pick(String, :code)
        @base_namespace     = opts.pick(:base_namespace) { nil }
        @no_base_namespace  = opts.pick(:no_base_namespace) { false }
        @encoding           = opts.pick(:encoding) { nil }
        @source             = opts.pick(:source) { nil }
      end
    end

    # Arguments
    #
    # :code       Mandatory argument of class String with the code to execute
    #             restricted in the sandbox
    #
    # :privileges Optional argument of class RubySandbox::Sandbox::Whitelist to
    #             indicate the restrictions of the code executed in the sandbox.
    #             The default is an empty Whitelist (absolutly no permission.)
    #             Must be of class Whitelist or passed as hash_key
    #             (:privileges => privileges)
    #
    # :binding   Optional argument with the binding object of the context where
    #            the code is to be executed. The default is a binding in the
    #            global context.
    #
    # :source    Optional argument to indicate the "source name", (visible in
    #            the backtraces). Only can be specified as hash parameter.
    #
    # :timeout   Optional argument to restrict the execution time of the script
    #            to a given value in seconds. (Accepts integer and decimal values),
    #            when timeout hits RubySandbox::TimeoutError is raised.
    #
    # :base_namespace   Alternate module to contain all classes and constants
    #                   defined by the unprivileged code if not specified, by
    #                   default, the base_namespace is created with the sandbox
    #                   itself.
    #
    # :no_base_namespace  Specify to do not use a base_namespace (default false,
    #                     not recommended to change.)
    #
    # :encoding  Specify the encoding of source (example: "utf-8"), the encoding
    #           also can be specified on header like a ruby normal source file.
    #
    # The arguments can be passed in any order and using hash notation or not:
    #
    #   sandbox.run code, privileges
    #   sandbox.run code, privileges: privileges
    #   sandbox.run code: code, privileges: privileges
    #   sandbox.run code, privileges, binding
    #   sandbox.run binding, code, privileges
    #   sandbox.run binding, code, privileges, source: source
    #   sandbox.run binding, code: code, privileges: privileges, source: source
    #
    def process_args(*args)
      opts   = Opts.new(*args)
      source = build_source(opts)
      assign_privileges_to_source(source, opts)
      assign_hook_handler(opts)
      [build_code(opts), source, opts.privileges]
    end

    def assign_privileges_to_source(source, opts)
      privileges[source] = opts.privileges
    end

    def assign_hook_handler(opts)
      base_ns       = opts.base_namespace
      @hook_handler = inst_hook_handler(base_ns) if base_ns
    end

    def build_encoding(opts)
      opts.encoding || get_source_encoding(opts.code)
    end

    def build_source(opts)
      opts.source || generate_id
    end

    def build_code(opts)
      code      = opts.code
      encoding  = build_encoding(opts)

      code = "nil;\n " + code
      code = wrap_code(code) unless opts.no_base_namespace
      code = "# encoding: #{encoding}\n" + code if encoding
      code
    end

    def inst_hook_handler(base_namespace)
      hook_handler = instantiate_evalhook_handler
      hook_handler.base_namespace = base_namespace
      hook_handler.sandbox = self
      hook_handler
    end

    # Generate a random source file name for the sandbox, used internally
    def generate_id
      "sandbox-#{SecureRandom.hex.slice(1, 10)}"
    end

    def create_hook_handler(*args)
      args    = Argument.new(args)
      source  = args.pick(:source) { generate_id }
      priv    = args.pick(Permissions, :privileges) { Whitelist.new }
      @base_namespace     = args.pick(:base_namespace) { create_adhoc_base_namespace }
      hook_handler        = inst_hook_handler(@base_namespace)
      privileges[source]  = priv
      hook_handler
    end

    def dispose
      @hook_handler_list.each(&:dispose)
    end

    private

    def instantiate_evalhook_handler
      newhookhandler = EvalhookHandler.new
      @hook_handler_list << newhookhandler
      newhookhandler
    end

    def create_adhoc_base_namespace
      rnd_module_name = "SandboxBasenamespace#{SecureRandom.hex.slice(1, 8)}"

      eval("module RubySandbox::Sandbox::#{rnd_module_name}; end")
      @base_namespace = eval("RubySandbox::Sandbox::#{rnd_module_name}")
      @base_namespace
    end

    def get_source_encoding(code)
      first_line = code.to_s.lines.first.to_s
      m = first_line.match(/encoding:(.*)$/)
      m[1] if m
    end
  end
  # rubocop:enable Metrics/ClassLength
end

RubySandbox.global_binding = binding
