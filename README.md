# RubySandbox - A secure sandbox for Ruby

RubySandbox is a configurable sandbox that ensures safe execution of untrusted Ruby code. It implements a Ruby interpreter in Ruby that provides APIs to allow user to hook into method calls while executing the code, and allow or deny a call by its class, instance of the receiver, name of the method or something else.

The permissions for each sandboxed run is fully configurable and the implementation of the methods called from within the sandbox can be replaced transparently.

## Installation

```
sudo gem install ruby_sandbox
```

## Usage

This examples and more can be found in examples directory

### Example

Hello world from a sandbox

```ruby
  s = RubySandbox.new
  priv = RubySandbox.whitelist
  priv.rule { allow_method(:print) }

  s.run(priv, 'print "hello world\n"')
  # => hello world
  s.run(priv, 'do_evil_stuff')
  # => SecurityError: Cannot invoke method do_evil_stuff on object of class Object
```

## Documentation

### Sandbox#run

TODO

### Permissions#rule

TODO

## Credit

RubySandbox is based on [shikashi](http://.github.com/tario) by [tario](http://.github.com/tario).

## Copyright

Copyright (c) 2018 Volkan Unsal, MIT

Copyright (c) 2010-2011 Dario Seminara, released under the GPL License (see LICENSE)
