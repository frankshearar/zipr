require 'zipr/either'

module Zipr
  class Zipper
    def down
      Left.new(:down_at_leaf_node)
    end
  end
end
