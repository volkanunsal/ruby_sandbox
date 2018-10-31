require 'shikashi/argument'
require 'shikashi/permissions'
require 'shikashi/whitelist'
require 'shikashi/blacklist'
require 'shikashi/version'
require 'shikashi/sandbox'

# Shikashi is a wrapper for Sandbox.
module Shikashi
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
