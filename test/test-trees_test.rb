require 'test/test_helper'

module Zipr
  describe TaggedTree do
    describe "rantly extensions" do
      it "should generate different trees" do
        trees = []
        property_of {
          sized(50) { tree }
        }.check {|t|
          trees << t
        }
        trees.zip(trees.drop(1) + trees.take(1)) { |i, j|
          i.should_not == j
        }
      end
    end

    describe "Zipper methods" do
      it "mknode returns a TaggedTree when given a non-TaggedTree" do
        t = Tree.new(1, [])
        t.zipper.mknode(1, []).should == Tree.new(1, [])
        t.zipper.mknode(1, [Tree.new(2, [])]).should == Tree.new(1, [Tree.new(2, [])])
      end

      it "mknode returns a TaggedTree when given a non-TaggedTree" do
        t = Tree.new(1, [])
        t.zipper.mknode(Tree.new(1, []), []).should == Tree.new(1, [])
        t.zipper.mknode(Tree.new(1, []), [Tree.new(2, [])]).should == Tree.new(1, [Tree.new(2, [])])
      end
    end

    describe :== do
      it "should be true for isomorphic trees" do
        x = Tree.new(1, [Tree.new(2, []), Tree.new(3, [])])
        y = Tree.new(1, [Tree.new(2, []), Tree.new(3, [])])
        x.should == y
        y.should == x
      end

      it "should be false for trees with different values" do
        x = Tree.new(1, [Tree.new(2, []), Tree.new(3, [])])
        y = Tree.new(2, [Tree.new(2, []), Tree.new(3, [])])
        x.should_not == y
        y.should_not == x
      end

      it "should be false for trees with different values in children" do
        x = Tree.new(1, [Tree.new(2, []), Tree.new(3, [])])
        y = Tree.new(1, [Tree.new(3, []), Tree.new(3, [])])
        x.should_not == y
        y.should_not == x
      end

      it "should be false for non-isomorphic trees" do
        x = Tree.new(1, [Tree.new(2, []), Tree.new(3, [])])
        y = Tree.new(2, [Tree.new(2, [])])
        x.should_not == y
        y.should_not == x
      end

      it "should be reflexive" do
        property_of {
          tree
        }.check {|t|
          t.should == t
        }
      end

      it "should not equal random nonsense" do
      property_of {
        choose(integer, string, boolean)
      }.check {|random_nonsense|
        Tree.new(1, []).should_not == random_nonsense
      }
      end

      it "should not equal nil" do
        property_of {
          tree
        }.check {|t|
          t.should_not == nil
        }
      end
    end

    describe :hash do
      it "should be true for isomorphic trees" do
        x = Tree.new(1, [Tree.new(2, []), Tree.new(3, [])])
        y = Tree.new(1, [Tree.new(2, []), Tree.new(3, [])])
        x.hash.should == y.hash
        y.hash.should == x.hash
      end

      it "should be false for trees with different values" do
        x = Tree.new(1, [Tree.new(2, []), Tree.new(3, [])])
        y = Tree.new(2, [Tree.new(2, []), Tree.new(3, [])])
        x.hash.should_not == y.hash
        y.hash.should_not == x.hash
      end

      it "should be false for trees with different values in children" do
        x = Tree.new(1, [Tree.new(2, []), Tree.new(3, [])])
        y = Tree.new(1, [Tree.new(3, []), Tree.new(3, [])])
        x.hash.should_not == y.hash
        y.hash.should_not == x.hash
      end

      it "should be false for non-isomorphic trees" do
        x = Tree.new(1, [Tree.new(2, []), Tree.new(3, [])])
        y = Tree.new(2, [Tree.new(2, [])])
        x.hash.should_not == y.hash
        y.hash.should_not == x.hash
      end

      it "should be reflexive" do
        property_of {
          tree
        }.check {|t|
          t.hash.should == t.hash
        }
      end
    end

    describe :to_s do
      it "should print empty trees" do
        Tree.new(1, []).to_s.should == '1'
      end

      it "should print trees with children" do
        Tree.new(1, [Tree.new(2, []), Tree.new(3, [])]).to_s.should == '1 [2, 3]'
      end
    end
  end

  describe Node do
    it "should be able to have children" do
      Node.new(1, []).branch?.should be_true
    end

    it "should be able to list its children, even when it has no children" do
      Node.new(1, []).children.should == []
    end

    it "should be able to list its children" do
      arr = [1, 2].map {|i| Leaf.new(i)}
      Node.new(1, arr).children.should == arr
    end

    it "should have an immutable list of children" do
      arr = [1, 2].map {|i| Leaf.new(i)}
      n = Node.new(1, arr)
      lambda {
        n.children << Leaf.new(3)
      }.should raise_error
    end

    it "should have an immutable tag" do
      n = Node.new([], [])
      lambda {
        n.tag << 1
      }.should raise_error
    end

    it "should have a depth of the deepest subtree, plus 1" do
      t = Leaf.value(1)
      (1..10).each {|i|
        t = Node.new(:unused, [t])
        t.depth.should == i + 1
      }
    end

    it "should have a size == 1 + sum of subtree sizes" do
      t = Leaf.value(1)
      (1..10).each {|i|
        t = Node.new(:unused, [t])
        t.size.should == i + 1
      }
    end

    it "should == an equivalent tree" do
      Node.new(:foo, []).should == Node.new(:foo, [])
      Node.new(:foo, [Leaf.value(1)]).should == Node.new(:foo, [Leaf.value(1)])
      Node.new(:foo, [Leaf.value(1),
                      Node.new(:bar, [Leaf.value(2)])]).should ==
        Node.new(:foo, [Leaf.value(1),
                        Node.new(:bar, [Leaf.value(2)])])
    end

    it "should not == tree with different tags" do
      Node.new(:foo, []).should_not == Node.new(:bar, [])
    end

    it "should not == tree with different children" do
      Node.new(1, []).should_not == Node.new(1, [Leaf.value(1)])
    end

    it "should not == random nonsense" do
      property_of {
        choose(integer, string, boolean)
      }.check {|random_nonsense|
        Node.new(1, []).should_not == random_nonsense
      }
    end

    it "should not == nil" do
      Node.new(1, []).should_not == nil
    end

    it "should have == hash to an equivalent tree" do
      Node.new(:foo, []).hash.should == Node.new(:foo, []).hash
      Node.new(:foo, [Leaf.value(1)]).hash.should == Node.new(:foo, [Leaf.value(1)]).hash
      Node.new(:foo, [Leaf.value(1),
                      Node.new(:bar, [Leaf.value(2)])]).hash.should ==
        Node.new(:foo, [Leaf.value(1),
                        Node.new(:bar, [Leaf.value(2)])]).hash
    end

    it "should not have == hash to a tree with different tag" do
      Node.new(:foo, []).hash.should_not == Node.new(:bar, []).hash
    end

    it "should not == tree with different children" do
      Node.new(1, []).hash.should_not == Node.new(1, [Leaf.value(1)]).hash
    end

    describe :to_s do
      it "should print malformed leaf Nodes properly" do
        Node.new(1, []).to_s.should == "(1 [])"
      end

      it "should print children" do
        Node.new(1, [Leaf.new(2), EmptyTree.new, Leaf.new(3)]).to_s.should == "(1 [2, #, 3])"
      end

      it "should print nested trees" do
        Node.new(1, [Node.new(2, [Leaf.new(3)])]).to_s.should == "(1 [(2 [3])])"
      end
    end
  end

  describe Leaf do
    it "should not be able to have children" do
      Leaf.new(1).branch?.should be_false
    end

    it "should have an immutable value" do
      l = Leaf.new([])
      lambda {
        l.value << 1
      }.should raise_error
    end

    it "should have a depth of 1" do
      Leaf.value(1).depth.should == 1
    end

    it "should have a size of 1" do
      Leaf.value(1).size.should == 1
    end

    it "should == something with == value" do
      property_of {
        choose(integer, string, boolean)
      }.check {|v|
        Leaf.value(v).should == Leaf.value(v)
      }
    end

    it "should not == something with != value" do
      property_of {
        i = choose(integer, string, boolean)
        j = choose(integer, string, boolean)
        guard(i != j)
        [i, j]
      }.check {|i, j|
        Leaf.value(i).should_not == Leaf.value(j)
      }
    end

    it "should not == random nonsense" do
      property_of {
        choose(integer, string, boolean)
      }.check {|random_nonsense|
        Leaf.value(1).should_not == random_nonsense
      }
    end

    it "should not == nil" do
      Leaf.value(1).should_not == nil
    end

    it "should have == things have the same hash" do
      property_of {
        choose(integer, string, boolean)
      }.check {|v|
        Leaf.value(v).hash.should == Leaf.value(v).hash
      }
    end

    it "should have different valued things have different hashes" do
      values = []
      property_of {
        i = choose(integer, string, boolean)
        j = choose(integer, string, boolean)
        guard(i != j)
        [i, j]
      }.check {|i, j|
        Leaf.value(i).hash.should_not == Leaf.value(j).hash
      }
    end

    describe :to_s do
      it "should print as its value" do
        Leaf.new(1).to_s.should == "1"
        Leaf.new(2).to_s.should == "2"
      end
    end
  end

  describe EmptyTree do
    it "should == another EmptyTree" do
      EmptyTree.new.should == EmptyTree.new
    end

    it "should not == random nonsense" do
      property_of {
        choose(integer, string, boolean)
      }.check {|random_nonsense|
        EmptyTree.new.should_not == random_nonsense
      }
    end

    it "should not == nil" do
      EmptyTree.new.should_not == nil
    end

    it "should have == hash to another EmptyTree" do
      EmptyTree.new.hash.should == EmptyTree.new.hash
    end

    it "should have a depth of 0" do
      EmptyTree.new.depth.should == 0
    end

    it "should have a size of 0" do
      EmptyTree.new.size.should == 0
    end

    describe :to_s do
      it "should print as a special character" do
        EmptyTree.new.to_s.should == "#"
      end
    end
  end
end
