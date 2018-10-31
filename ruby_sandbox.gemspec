lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruby_sandbox/version'

Gem::Specification.new do |spec|
  spec.name          = 'ruby_sandbox'
  spec.version       = RubySandbox::VERSION
  spec.authors       = ['Volkan Unsal', 'Dario Seminara']
  spec.email         = ['spocksplanet@gmail.com', 'robertodarioseminara@gmail.com']
  spec.summary       = 'ruby_sandbox is a code sandbox that permits safe execution of "unprivileged" scripts.'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  unless spec.respond_to?(:metadata)
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'evalhook', '>= 0.6.0'
  spec.add_dependency 'getsource', '>= 0.1.0'

  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'pry', '~> 0.11'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.8'
  spec.add_development_dependency 'rubocop', '~> 0.60'
end
