# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "shikashi/version"

Gem::Specification.new do |spec|
  spec.name          = "shikashi"
  spec.version       = Shikashi::VERSION
  spec.authors       = ['Dario Seminara', "Volkan Unsal"]
  spec.email         = ['robertodarioseminara@gmail.com', "spocksplanet@gmail.com"]

  spec.summary       = 'shikashi is a ruby sandbox that permits the execution of "unprivileged" scripts by defining the permitted methods and constants the scripts can invoke with a white list logic'
  spec.homepage      = "http://github.com/tario/shikashi"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  raise "RubyGems 2.0 or newer is required to protect against " \
    "public gem pushes." unless spec.respond_to?(:metadata)


  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "evalhook", ">= 0.6.0"
  spec.add_dependency "getsource", ">= 0.1.0"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry", "~> 0.11"
end


