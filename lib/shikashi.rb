require 'shikashi/argument'
require 'shikashi/permissions'
require 'shikashi/whitelist'
require 'shikashi/blacklist'
require 'shikashi/version'
require 'shikashi/sandbox'

# Shikashi is a wrapper for Sandbox.
module Shikashi
  # Backward compatibility
  Privileges = Whitelist

  # TODO: test
  def self.new
    Sandbox.new
  end

  # TODO: test
  def self.privileges(strategy = :whitelist)
    case strategy
    when :whitelist
      Whitelist.new
    when :blacklist
      Blacklist.new
    end
  end
end
