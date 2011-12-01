require 'zipr/either'

module Zipr
  describe Either do
    it "should allow creation of Right values" do
      Right.new(1).should_not be_nil
    end

    it "should allow creation of Left values" do
      Left.new(:foo).should_not be_nil
    end

    it "should mark Rights" do
      Right.new(1).should be_right
      Left.new(:foo).should_not be_right
    end

    it "should mark Lefts" do
      Right.new(1).should_not be_left
      Left.new(:foo).should be_left
    end
  end
end
