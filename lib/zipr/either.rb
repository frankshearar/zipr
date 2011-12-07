require 'zipr/unsupported-operation'

module Zipr
  class Either
    def either(right_fn, left_fn)
      raise UnsupportedOperation.new(:either, self)
    end

    def left?
      false
    end

    def right?
      false
    end
  end

  class Right < Either
    attr_reader :value

    def initialize(obj)
      @value = obj
    end

    def either(right_fn, left_fn)
      right_fn.call(self)
    end

    def right?
      true
    end
  end

  class Left < Either
    attr_reader :error
    
    def initialize(symbol)
      @error = symbol
    end

    def either(right_fn, left_fn)
      left_fn.call(self)
    end

    def left?
      true
    end
  end
end
