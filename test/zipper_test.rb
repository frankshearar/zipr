require 'zipr/zipper'
require 'rantly/property'
require 'rspec'

module Zipr
  class Tree
    def branch?
      false
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


module Zipr
  describe Zipper do
    it "should allow zipping on a structure" do
      Zipper.new(Leaf.new(1)).should_not be_nil
    end

    it "should record an error going down on a leaf" do
      Zipper.new(Leaf.new(1)).down.should be_left
    end
  end
end
