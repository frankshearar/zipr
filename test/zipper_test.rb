require 'zipr/zipper'
require 'rantly/property'
require 'rspec'

module Zipr
  describe Zipper do
    it "should allow zipping on a structure" do
      Zipper.zip_on(Leaf.new(1), ->{false}, ->{[]}, ->{nil}).should_not be_nil
    end

    it "should record an error going down on a leaf" do
      l = Leaf.new(1).zipper.safe_down
      l.should be_left
      l.error.should == :down_at_leaf
    end

    it "should allow down on a branch point" do
      t = Node.new(:unimportant, [Leaf.new(1)])
      z = t.zipper.safe_down
      z.should be_right
      new_zipper = z.value
      new_zipper.class.should == Zipper
      new_zipper.value.class.should == Leaf
      new_zipper.value.value.should == 1
    end

    it "should provide an 'unsafe' down" do
      t = Node.new(:unimportant, [Leaf.new(1)])
      z = t.zipper.down
      z.class.should == Zipper
      z.value.class.should == Leaf
      z.value.value.should == 1
    end

    it "should have unsafe down fail on a leaf" do
      ->{
        Leaf.new(1).zipper.down
      }.should raise_error(ZipperNavigationError) { |e|
        e.to_s.should == "Navigation error - :down_at_leaf"
      }
    end

    it "should forbid up at the root node" do
      z = Leaf.new(1).zipper.safe_up
      z.should be_left
      z.error.should == :up_at_root
    end

    it "should have up move to the parent node" do
      t = Node.new(1, [Leaf.new(1)])
      z = t.zipper.down.safe_up
      z.should be_right
      new_zipper = z.value
      new_zipper.value.class.should == Node
      new_zipper.value.tag.should == 1
    end

    it "should have down then up be an idempotent navigation" do
      property_of {
        t = sized(50) { tree }
        guard(t.depth > 1)
        t
      }.check {|t|
        t.zipper.down.up.value.should == t
      }
    end

    it "should root on a trivial structure" do
      t = Leaf.new(1)
      t.zipper.root.should == t
    end
  end
end

class Rantly
  def max_subtrees
    10
  end

  def tree(n = self.size)
    if (n <= 0) then
      Zipr::EmptyTree.new
    elsif (n == 1) then
      Zipr::Leaf.value(any)
    else
      num_subtrees = integer(0..max_subtrees)
      subtrees = []
      sz = n
      while (sz > 0) do
        t = tree(integer(0..(n - 1)))
        subtrees << t
        sz -= t.size
      end
      Zipr::Node.new(any, subtrees)
    end
  end

  def any
    choose(integer, string, boolean)
  end
end

module Zipr
  class TaggedTree
    def branch?
      false
    end

    def zipper
      mknode = -> value,children {
        if children.empty? then
          Leaf(value)
        else
          Node.new(value, children)
        end
      }

      Zipper.zip_on(self, :branch?, :children, mknode)
    end
  end

  class Node < TaggedTree
    attr_reader :children
    attr_reader :tag

    def initialize(tag, children)
      @tag = tag
      @children = children
      children.freeze
      tag.freeze
      freeze
    end

    def ==(obj)
      case obj
        when Node then @tag == obj.tag and @children == obj.children
        else false
      end
    end

    def hash
      (41 * (41 * 1) + tag.hash) + children.hash
    end

    def branch?
      true
    end

    def depth
      max_subtree_depth = children.map {|c| c.depth}.max
      (max_subtree_depth || 0) + 1
    end

    def size
      subtree_size = children.map {|c| c.size}.reduce(:+)
      (subtree_size || 0) + 1
    end
  end

  class Leaf < TaggedTree
    attr_reader :value

    def self.value(obj)
      Leaf.new(obj)
    end

    def initialize(value)
      @value = value
      value.freeze
      freeze
    end

    def ==(obj)
      case obj
        when Leaf then @value == obj.value
        else false
      end
    end

    def hash
      @value.hash
    end

    def depth
      1
    end

    def size
      1
    end
  end

  class EmptyTree < TaggedTree
    def ==(obj)
      case obj
        when EmptyTree then true
        else false
      end
    end

    def hash
      0
    end

    def depth
      0
    end

    def size
      0
    end
  end

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
      ->{n.children << Leaf.new(3)}.should raise_error
    end

    it "should have an immutable tag" do
      n = Node.new([], [])
      ->{n.tag << 1}.should raise_error
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
      ->{l.value << 1}.should raise_error
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
