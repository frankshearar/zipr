module Zipr
  class Either
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

    def right?
      true
    end
  end

  class Left < Either
    attr_reader :error
    
    def initialize(symbol)
      @error = symbol
    end

    def left?
      true
    end
  end
end
