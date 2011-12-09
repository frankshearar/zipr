require 'zipr/either'
require 'zipr/rantly-extensions'
require 'rspec'

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

    it "should have Rights of == things be ==" do
      property_of {
        any
      }.check { |thing|
        Right.new(thing).should == Right.new(thing)
      }
    end

    it "should have Rights of not == things not be ==" do
      property_of {
        i = any
        j = any
        guard(i != j)
        [i, j]
      }.check { |thing1, thing2|
        Right.new(thing1).should_not == Right.new(thing2)
      }
    end

    it "should have hashes of Rights of == things be ==" do
      property_of {
        any
      }.check { |thing|
        Right.new(thing).hash.should == Right.new(thing).hash
      }
    end

    it "should have hashes of Rights of not == things not be ==" do
      property_of {
        i = any
        j = any
        guard(i != j)
        [i, j]
      }.check { |thing1, thing2|
        Right.new(thing1).hash.should_not == Right.new(thing2).hash
      }
    end

    it "should have Lefts of == things be ==" do
      property_of {
        any
      }.check { |thing|
        Left.new(thing).should == Left.new(thing)
      }
    end

    it "should have Lefts of not == things not be ==" do
      property_of {
        i = any
        j = any
        guard(i != j)
        [i, j]
      }.check { |thing1, thing2|
        Left.new(thing1).should_not == Left.new(thing2)
      }
    end

    it "should have hashes of Lefts of == things be ==" do
      property_of {
        any
      }.check { |thing|
        Left.new(thing).hash.should == Left.new(thing).hash
      }
    end

    it "should have hashes of Lefts of not == things not be ==" do
      property_of {
        i = any
        j = any
        guard(i != j)
        [i, j]
      }.check { |thing1, thing2|
        Left.new(thing1).hash.should_not == Left.new(thing2).hash
      }
    end

    it "should never have Lefts and Rights ==" do
      property_of {
        any
      }.check { |thing|
        Left.new(thing).should_not == Right.new(thing)
      }
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

    it "should not run :then when given a Left" do
      l = Left.new(1).then {|i| Left.new(i + 1)}
      l.should be_left
      l.error.should == 1
    end

    it "should pass the wrapped value into the block to :then" do
      arg = nil
      Right.new(:wrapped).then {|s| arg = s; Right.new(s)}
      arg.should == :wrapped
    end

    it "should run :then when given a Right" do
      r = Right.new(1).then {|i| Right.new(i + 1)}
      r.should be_right
      r.value.should == 2
    end

    it "should compose a sequence of :then calls" do
      arg_1 = nil
      arg_2 = nil
      result = Right.new(1).then {|i|
        arg_1 = i
        Right.new(i + 1)
      }.then {|i|
        arg_2 = i
        Right.new(i + 2)}
      arg_1.should == 1
      arg_2.should == 2
      result.should be_right
      result.value.should == 1 + 1 + 2
    end

    it "should not allow calling :then with both proc and block" do
      ->{
        Right.new(1).then(->x{x + 1}) {|i| i + 1}
      }.should raise_error(ArgumentError) {|e|
        e.to_s.should include("Proc")
        e.to_s.should include("both")
        e.to_s.should include("block")
      }
    end

    it "should not allow calling :then with neither a proc nor a block" do
      ->{
        Right.new(1).then
      }.should raise_error(ArgumentError) {|e|
        e.to_s.should include("Proc")
        e.to_s.should include("neither")
        e.to_s.should include("block")
      }
    end

    it "should obey the first monadic law: left identity" do
      double = ->x{Right.new(x + x)}
      property_of {
        thing = any
        guard(thing.respond_to?(:+))
        thing
      }.check { |thing|
        Right.new(thing).then(double).should == double.call(thing)
      }
    end

    it "should obey the second monadic law: right identity" do
      return_fn = ->x{Right.new(x)}
      property_of {
        thing = any
        guard(thing.respond_to?(:+))
        thing
      }.check { |thing|
        monadic_value = Right.new(thing)
        monadic_value.then(return_fn).should == monadic_value
      }
    end

    it "should obey the third monadic law: associativity" do
      double = ->x{Right.new(x + x)}
      add_2 = ->x{Right.new(x + 2)}
      property_of {
        any
      }.check { |thing|
        m = Right.new(1)
        (m.then(double)).then(add_2).should == m.then(->x{double.call(x).then(add_2)})
      }
    end
  end
end
