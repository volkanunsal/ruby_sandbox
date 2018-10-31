require 'evalhook'
require 'getsource'
require 'timeout'
require 'shikashi/privileges'
require 'shikashi/eval_hook_handler'
require 'shikashi/sandbox/packet'

# Shikashi is the module namespace
module Shikashi
  class << self
    attr_accessor :global_binding
  end

  module Timeout
    # raised when reach the timeout in a script execution restricted by timeout (see Sandbox#run)
    class Error < RuntimeError
    end
  end

  # rubocop:disable Metrics/ClassLength
  # The sandbox class runs the sandbox. Only one instance of sandbox can be defined
  # per thread (each thread may have its own sandbox running.)
  #
  #= Example
  #
  # require "rubygems"
  # require "shikashi"
  #
  # include Shikashi
  #
  # s = Sandbox.new
  # priv = Privileges.new
  # priv.allow_method :print
  #
  # s.run(priv, 'print "hello world\n"')
  class Sandbox
    # array of privileges of restricted code within sandbox
    #
    # Example
    # sandbox.privileges[source].allow_method :raise
    #
    attr_reader :privileges

    # Binding of execution, the default is a binding in a global context allowing the definition of module of classes
    attr_reader :chain

    attr_reader :hook_handler

    # Same as Sandbox.new.run
    def self.run(*args)
      Sandbox.new.run(Shikashi.global_binding, *args)
    end

    # Run the code in sandbox with the given privileges
    #
    #   (see examples)
    #
    # Arguments
    #
    # :code       Mandatory argument of class String with the code to execute
    #             restricted in the sandbox
    #
    # :privileges Optional argument of class Shikashi::Sandbox::Privileges to
    #             indicate the restrictions of the code executed in the sandbox.
    #             The default is an empty Privileges (absolutly no permission.)
    #             Must be of class Privileges or passed as hash_key
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
    #            when timeout hits Shikashi::Timeout::Error is raised.
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
    # The arguments can be passed in any order and using hash notation or not, examples:
    #
    # sandbox.run code, privileges
    # sandbox.run code, :privileges => privileges
    # sandbox.run :code => code, :privileges => privileges
    # sandbox.run code, privileges, binding
    # sandbox.run binding, code, privileges
    # #etc
    # sandbox.run binding, code, privileges, :source => source
    # sandbox.run binding, :code => code, :privileges => privileges, :source => source
    #
    # Example:
    #
    # require "rubygems"
    # require "shikashi"
    #
    # include Shikashi
    #
    # sandbox = Sandbox.new
    # privileges = Privileges.new
    # privileges.allow_method :print
    # sandbox.run('print "hello world\n"', :privileges => privileges)
    #
    # Example 2:
    # require "rubygems"
    # require "shikashi"
    #
    # include Shikashi
    #
    # sandbox = Sandbox.new
    # privileges = Privileges.new
    # privileges.allow_method :print
    # privileges.allow_method :singleton_method_added
    #
    # sandbox.run('
    #   def self.foo
    #     print "hello world\n"
    #   end', :privileges => privileges)
    #
    def run(*args)
      opts = Argument.new(args)
      t = opts.pick(:timeout) { nil }
      raise Shikashi::Timeout::Error if t == 0

      t ||= 0

      if block_given?
        yield
      else
        ::Timeout.timeout(t) { run_i(*args) }
      end
    rescue ::Timeout::Error
      raise Shikashi::Timeout::Error
    end

    def run_i(*args)
      opts = Argument.new(args)
      binding_ = opts.pick(Binding, :binding) { Shikashi.global_binding }
      code, hook_handler, source = prepare_code(*args)
      hook_handler.evalhook(code, binding_, source)
    end

    # TODO: test
    def wrap_code(code, base_namespace)
      is_module = eval(base_namespace.to_s).instance_of? Module
      if is_module
        "module #{base_namespace}\n #{code}\n end\n"
      else
        "class #{base_namespace}\n #{code}\n end\n"
      end
    end

    # Creates a packet of code with the given privileges to execute later as
    # many times as neccessary
    #
    #   (see examples)
    #
    # Arguments
    #
    # :code             Mandatory argument of class String with the code to
    #                   execute restricted in the sandbox
    #
    # :privileges       Optional argument of class Shikashi::Sandbox::Privileges
    #                   to indicate the restrictions of the code executed in
    #                   the sandbox. The default is an empty Privileges (absolutely
    #                   no permission.) Must be of class Privileges or passed
    #                   as hash_key (:privileges => privileges)
    #
    # :source           Optional argument to indicate the "source name",
    #                   (visible in the backtraces). Only can be specified as
    #                   hash parameter.
    #
    # :base_namespace   Alternate module to contain all classes and constants
    #                   defined by the unprivileged code. If not specified, by
    #                   default, the base_namespace is created with the sandbox
    #                   itself.
    #
    # :no_base_namespace  Specify to do not use a base_namespace (default false,
    #                     not recommended to change.)
    #
    # :encoding         Specify the encoding of source (example: "utf-8"), the
    #                   encoding also can be specified on header like a ruby
    #                   normal source file.
    #
    # NOTE: arguments are the same as for Sandbox#run method, except for timeout
    # and binding which can be used when calling Shikashi::Sandbox::Packet#run.
    #
    # Example:
    #
    # require "rubygems"
    # require "shikashi"
    #
    # include Shikashi
    #
    # sandbox = Sandbox.new
    #
    # privileges = Privileges.allow_method(:print)
    #
    # # this is equivallent to sandbox.run('print "hello world\n"')
    # packet = sandbox.packet('print "hello world\n"', privileges)
    # packet.run
    #
    def packet(*args)
      code, _hook_handler, source, privileges_ = prepare_code(*args)
      evalhook_packet = @hook_handler.packet(code)
      Shikashi::Sandbox::Packet.new(evalhook_packet, privileges_, source)
    end

    # rubocop:disable Metrics/AbcSize
    def prepare_code(*args)
      opts = Argument.new(args)
      privileges_ = opts.pick(Privileges, :privileges) { Privileges.new }
      code = opts.pick(String, :code)
      base_namespace = opts.pick(:base_namespace) { nil }
      no_base_namespace = opts.pick(:no_base_namespace) { @no_base_namespace }
      encoding = get_source_encoding(code) || opts.pick(:encoding) { nil }
      source = opts.pick(:source) { generate_id }

      hook_handler = @hook_handler
      hook_handler = inst_hook_handler(base_namespace) if base_namespace
      base_namespace = hook_handler.base_namespace

      privileges[source] = privileges_

      code = "nil;\n " + code
      code = wrap_code(code, base_namespace) unless no_base_namespace
      code = "# encoding: #{encoding}\n" + code if encoding

      [code, hook_handler, source, privileges_]
    end
    # rubocop:enable Metrics/AbcSize

    def inst_hook_handler(base_namespace)
      hook_handler = instantiate_evalhook_handler
      hook_handler.base_namespace = base_namespace
      hook_handler.sandbox = self
      hook_handler
    end

    # Generate a random source file name for the sandbox, used internally
    def generate_id
      "sandbox-#{rand(1_000_000)}"
    end

    def initialize
      @privileges = {}
      @chain = {}
      @hook_handler_list = []
      @hook_handler = instantiate_evalhook_handler
      @hook_handler.sandbox = self
      @base_namespace = create_adhoc_base_namespace
      @hook_handler.base_namespace = @base_namespace
    end

    # add a chain of sources, used internally
    def add_source_chain(outer, inner)
      @chain[inner] = outer
    end

    attr_reader :base_namespace

    def create_hook_handler(*args)
      args = Argument.new(args)

      hook_handler = instantiate_evalhook_handler
      hook_handler.sandbox = self
      @base_namespace = args.pick(:base_namespace) { create_adhoc_base_namespace }
      hook_handler.base_namespace = @base_namespace

      source = args.pick(:source) { generate_id }
      privileges_ = args.pick(Privileges, :privileges) { Privileges.new }

      privileges[source] = privileges_

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
      rnd_module_name = "SandboxBasenamespace#{rand(100_000_000)}"

      eval("module Shikashi::Sandbox::#{rnd_module_name}; end")
      @base_namespace = eval("Shikashi::Sandbox::#{rnd_module_name}")
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

Shikashi.global_binding = binding
