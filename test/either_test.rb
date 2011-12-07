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

    it "should run the first argument of either when Right" do
      ->{
        Right.new(1).either(->x{x}, ->x{raise "This is the wrong Proc."})
      }.should_not raise_error
    end

    it "should return the result of either's first argument when Right" do
      Right.new(1).either(->x{x.value}, ->x{raise "This is the wrong Proc."}).should == 1
    end

    it "should run the second argument of either when Left" do
      ->{
        Left.new(:foo).either(->x{raise "This is the wrong Proc."}, ->x{x.error})
      }.should_not raise_error
    end

    it "should return the result of either's second argument when Left" do
      Left.new(:foo).either(->x{raise "This is the wrong Proc."}, ->x{x.error}).should == :foo
    end
  end
end
