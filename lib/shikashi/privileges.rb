=begin

This file is part of the shikashi project, http://github.com/tario/shikashi

Copyright (c) 2009-2010 Roberto Dario Seminara <robertodarioseminara@gmail.com>

shikashi is free software: you can redistribute it and/or modify
it under the terms of the gnu general public license as published by
the free software foundation, either version 3 of the license, or
(at your option) any later version.

shikashi is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.  see the
gnu general public license for more details.

you should have received a copy of the gnu general public license
along with shikashi.  if not, see <http://www.gnu.org/licenses/>.

=end

module Shikashi
#
#The Privileges class represent permissions about methods and objects
#
class Privileges

  class AllowedMethods
    def initialize
      @allowed_methods = Array.new
      @all = false
    end

    def allowed?(mn)
       if @all
         true
       else
         @allowed_methods.include?(mn)
       end
    end

    def allow(mn)
      @allowed_methods << mn
    end

    def allow_all
      @all = true
    end
  end

  def initialize
    @allowed_objects = Hash.new
    @allowed_methods = Array.new
  end

  def object(obj)
    tmp = nil
    unless @allowed_objects[obj.__id__]
      tmp = AllowedMethods.new
      @allowed_objects[obj.__id__] = tmp
    end
    tmp
  end
  # allow the execution of method named method_name whereever
  def allow_method(method_name)
    @allowed_methods << method_name
  end

  def allow?(klass, recv, method_name, method_id)

    return true if @allowed_methods.include?(method_name)

    tmp = @allowed_objects[recv]
    if tmp
      if tmp.allow(method_name)
        return true
      end
    end

    false
  end
end

end