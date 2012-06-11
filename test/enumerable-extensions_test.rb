require './test_helper'

describe Enumerable do
  describe "creating a zipper" do
    [].zipper.class.should == Zipr::Zipper
  end

  describe "branching" do
    it "should return true for Enumerable things" do
      z = [].zipper
      z.branch?([]).should be_true
      z.branch?({}).should be_true
    end

    it "should return false for everything else" do
      z = [].zipper
      z.branch?(1).should be_false
      z.branch?("string").should be_false
      z.branch?(:symbol).should be_false
    end
  end

  describe "children" do
    it "should return the Enumerable itself" do
      z = [].zipper
      z.children([]).should == []
      z.children([1]).should == [1]
      z.children([1,2,3]).should == [1,2,3]
    end
  end

  describe "making new nodes" do
    it "should retain change mutations in branch nodes" do
      z = [1, [2, 3]].zipper
      z = z.down.right.change{|a| a.map{|i |i + 1}}
      z.root.should == [1, [3, 4]]
    end

    it "should retain change mutations in leaf nodes" do
      z = [1, [2, 3]].zipper
      z = z.down.right.down.change{|i| i + 1}
      z.root.should == [1, [3, 3]]
    end

    it "should retain replace mutations in branch nodes" do
      z = [1, [2, 3]].zipper
      z = z.down.right.replace([:a, :b])
      z.root.should == [1, [:a, :b]]
    end

    it "should retain replace mutations in leaf nodes" do
      z = [1, [2, 3]].zipper
      z = z.down.right.down.replace(99)
      z.root.should == [1, [99, 3]]
    end
  end
end
