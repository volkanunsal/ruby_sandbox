  
require 'ruby_sandbox'

s = RubySandbox::Sandbox.new
perm = RubySandbox::Whitelist.new

perm.allow_method :sleep

s.run(perm, 'sleep 3', timeout: 2) # raise RubySandbox::Timeout::Error after 2 seconds
