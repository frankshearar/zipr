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
      t = Node.new(nil, [Leaf.new(1)])
      z = t.zipper.safe_down
      z.should be_right
      new_zipper = z.value
      new_zipper.class.should == Zipper
      new_zipper.value.class.should == Leaf
      new_zipper.value.value.should == 1
    end

    it "should root on a trivial structure" do
      t = Leaf.new(1)
      t.zipper.root.should == t
    end
  end
end

module Zipr
  class Tree
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

  class Node < Tree
    attr_reader :children
    attr_reader :tag

    def initialize(tag, children)
      @tag = tag
      @children = children
      children.freeze
      tag.freeze
      freeze
    end

    def branch?
      true
    end
  end

  class Leaf < Tree
    attr_reader :value

    def initialize(value)
      @value = value
      value.freeze
      freeze
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
  end

  describe Leaf do
    it "should not be able to have children" do
      Leaf.new(1).branch?.should be_false
    end

    it "should have an immutable value" do
      l = Leaf.new([])
      ->{l.value << 1}.should raise_error
    end
  end
end
