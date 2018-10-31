require 'ruby_sandbox/argument'
require 'ruby_sandbox/permissions'
require 'ruby_sandbox/whitelist'
require 'ruby_sandbox/blacklist'
require 'ruby_sandbox/version'
require 'ruby_sandbox/sandbox'

# RubySandbox is a wrapper for Sandbox.
module RubySandbox
  def self.new
    Sandbox.new
  end

  def self.build(strategy = :blacklist)
    case strategy
    when :whitelist
      Whitelist.new
    when :blacklist, nil
      priv = Blacklist.new
      priv.safe!
    end
  end
end
