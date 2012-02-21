require 'rantly/property'
require 'rspec'
require 'zipr/rantly-extensions'
require 'zipr/test-trees'

module Zipr
  describe TaggedTree do
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
      lambda {n.children << Leaf.new(3)}.should raise_error
    end

    it "should have an immutable tag" do
      n = Node.new([], [])
      lambda {n.tag << 1}.should raise_error
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
  end

  describe Leaf do
    it "should not be able to have children" do
      Leaf.new(1).branch?.should be_false
    end

    it "should have an immutable value" do
      l = Leaf.new([])
      lambda {l.value << 1}.should raise_error
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
  end

  describe EmptyTree do
    it "should == another EmptyTree" do
      EmptyTree.new.should == EmptyTree.new
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
  end
end
