require 'ruby_sandbox/dsl'
require 'ruby_sandbox/argument'
require 'ruby_sandbox/dsl/permissions'
require 'ruby_sandbox/dsl/whitelist'
require 'ruby_sandbox/dsl/blacklist'
require 'ruby_sandbox/version'
require 'ruby_sandbox/sandbox'

# RubySandbox is a wrapper for Sandbox.
module RubySandbox
  module_function
  class << self
    attr_accessor :global_binding
  end
  Permissions = Dsl::Permissions
  Whitelist = Dsl::Whitelist
  Blacklist = Dsl::Blacklist
  # raised when reach the timeout in a script execution restricted by timeout.
  TimeoutError = Class.new(RuntimeError)

  def new
    Sandbox.new
  end

  def whitelist
    build(:whitelist)
  end

  def blacklist
    build
  end

  def build(strategy = :blacklist)
    case strategy
    when :whitelist
      Whitelist.new
    when :blacklist, nil
      priv = Blacklist.new
      priv.safe!
    end
  end
end

RubySandbox.global_binding = binding
