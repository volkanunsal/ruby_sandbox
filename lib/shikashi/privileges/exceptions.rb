module Shikashi
  # Define the permissions needed to raise exceptions within the sandbox
  #
  class Privileges
    def allow_exceptions
      allow_method :raise
      methods_of(Exception).allow :backtrace, :set_backtrace, :exception
    end
  end
end
