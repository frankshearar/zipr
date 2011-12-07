module Zipr
  class UnsupportedOperation < Exception
    attr_reader :method_name
    attr_reader :parameter

    def initialize(method_name, param)
      @method_name = method_name
      @parameter = param
    end

    def to_s
      "Method #{method_name.inspect} called with unsupported parameter type #{parameter.class.name}"
    end
  end
end
