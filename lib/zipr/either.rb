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

    def then(&unary_block)
      self
    end
  end

  class Right < Either
    attr_reader :value

    def initialize(obj)
      @value = obj
    end

    def ==(obj)
      case obj
        when Right then value == obj.value
        else false
      end
    end

    def hash
      value.hash
    end

    def either(right_fn, left_fn)
      right_fn.call(self.value)
    end

    def right?
      true
    end

    def then(unary_block = nil, &given_unary_block)
      if unary_block.nil? and not block_given? then
        raise ArgumentError.new("Cannot invoke :then with neither a Proc and a block")
      end
      
      if unary_block.nil? then
        given_unary_block.call(value)
      elsif not block_given? then
        unary_block.call(value)
      else
        raise ArgumentError.new("Cannot invoke :then with both a Proc and a block")
      end
    end
  end

  class Left < Either
    attr_reader :error
    
    def initialize(symbol)
      @error = symbol
    end

    def ==(obj)
      case obj
        when Left then error == obj.error
        else false
      end
    end

    def hash
      error.hash
    end

    def either(right_fn, left_fn)
      left_fn.call(self.error)
    end

    def left?
      true
    end
  end
end
