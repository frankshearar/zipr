require_relative 'test_helper'

module Zipr
  describe Id do
    it "should return the argument given it" do
      property_of {
        choose(integer, float, tree, string)
      }.check {|x|
        x.equal?(x).should be_true
      }
    end
  end
end
