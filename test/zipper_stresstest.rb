require './test_helper'

module Zipr
  describe "Zipper stress tests" do
    it "should be able to process large structures" do
      # The traversal uses a trampoline to navigate to the (great)^n-uncle
      # of a rightmost node. This test throws a pathological tree at the
      # traversal to demonstrate that the trampoline does, indeed, permit
      # extremely deep recursion.
      deepness = 10000

      short_right = Leaf.new(2)
      long_left = Leaf.new(1)
      deepness.downto(1) { |i|
        long_left = Node.new(i, [long_left])
      }
      tree = Node.new(0, [long_left, short_right])
      t = PreOrderTraversal.new(tree.zipper)
      arr = []
      t.each { |node|
        case node
          when Node then arr << node.tag
          when Leaf then;
        end
      }
      arr.should == (0..deepness).to_a
    end
  end
end
