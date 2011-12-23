module Zipr
  module Boing
    def trampoline(initial_value, &unary_block)
      result = unary_block.call(initial_value)
      while result.kind_of?(Proc) do
        result = unary_block.call(result.call)
      end
      result
    end
  end
end
