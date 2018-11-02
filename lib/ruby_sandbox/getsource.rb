class Method

  class Node

    attr_reader :file
    attr_reader :line

    def initialize(file_,line_)
      @file = file_
      @line = line_
    end
  end

  begin
    instance_method("body")
  rescue
    def body
      if source_location
        Method::Node.new(source_location[0], source_location[1])
      else
        Method::Node.new("",0)
      end
    end
  end
end

class UnboundMethod
  begin
    instance_method("body")
  rescue
    def body
      if source_location
        Method::Node.new(source_location[0], source_location[1])
      else
        Method::Node.new("",0)
      end
    end
  end
end


class Object

  def specific_method(arg1, arg2=nil)
    if arg2
      method_name = arg2
      klass = arg1

      if instance_of? Class
        method(method_name)
      else
        klass.instance_method(method_name).bind(self)
      end
    else
      method(arg1)
    end
  end
end