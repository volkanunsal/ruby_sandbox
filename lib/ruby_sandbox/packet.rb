module RubySandbox
  # Packet class stores an executable code in memory for later use.
  #
  class Packet
    def initialize(evalhook_packet, default_privileges, source) #:nodoc:
      @evalhook_packet = evalhook_packet
      @default_privileges = default_privileges
      @source = source
    end

    # Run the code in the package
    #
    # call-seq: run(arguments)
    #
    # Arguments
    #
    # :binding    Optional argument with the binding object of the context
    #             where the code is to be executed. The default is a binding
    #             in the global context.
    #
    # :timeout    Optional argument to restrict the execution time of the
    #             script to a given value in seconds.
    #
    def run(*args)
      args = Argument.new(args)
      t = args.pick(:timeout) { nil }
      binding_ = args.pick(Binding, :binding) { nil }

      ::Timeout.timeout t do
        @evalhook_packet.run(binding_, @source, 0)
      end
    rescue ::Timeout::Error
      raise RubySandbox::Timeout::Error
    end

    # Dispose the objects associated with this code package
    def dispose
      @evalhook_packet.dispose
    end
  end
end
