require_relative 'test_helper'

if sexp_loaded then
  require 'zipr/enumerable-extensions'
  require 'zipr/zipper'

  describe Sexp do
    describe "creating a zipper" do
      s().zipper.class.should == Zipr::Zipper
      s(s(s(3))).zipper.down.down.insert_child(4).root.should == s(s(s(4, 3)))
    end

    describe "branching" do
      it "should return true for Enumerable things" do
        z = s().zipper
        z.branch?([]).should be_true
        z.branch?(s()).should be_true
        z.branch?({}).should be_true
      end

      it "should return false for everything else" do
        z = s().zipper
        z.branch?(1).should be_false
        z.branch?("string").should be_false
        z.branch?(:symbol).should be_false
      end
    end

    describe "children" do
      it "should return the Enumerable itself" do
        z = s().zipper
        z.children(s()).should == s()
        z.children(s(1)).should == s(1)
        z.children(s(1,2,3)).should == s(1,2,3)
      end
    end

    describe "making new nodes" do
      it "should retain change mutations in branch nodes" do
        z = s(1, s(2, 3)).zipper
        z = z.down.right.change{|a| a.map{|i |i + 1}}
        z.root.should == s(1, s(3, 4))
      end

      it "should retain change mutations in leaf nodes" do
        z = s(1, s(2, 3)).zipper
        z = z.down.right.down.change{|i| i + 1}
        z.root.should == s(1, s(3, 3))
      end

      it "should retain replace mutations in branch nodes" do
        z = s(1, s(2, 3)).zipper
        z = z.down.right.replace(s(:a, :b))
        z.root.should == s(1, s(:a, :b))
      end

      it "should retain replace mutations in leaf nodes" do
        z = s(1, s(2, 3)).zipper
        z = z.down.right.down.replace(99)
        z.root.should == s(1, s(99, 3))
      end
    end
  end
end
