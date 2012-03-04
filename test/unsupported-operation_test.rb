require 'test/test_helper'

module Zipr
  describe UnsupportedOperation do
    describe :to_s do
      it "should mention the method causing the problem" do
        s = UnsupportedOperation.new(:either, 1).to_s
        s.index(:either.to_s).should  > 0
      end

      it "should mention the parameter type causing the problem" do
        s = UnsupportedOperation.new(:either, "string").to_s
        s.index("string".class.name).should  > 0
      end
    end
  end
end
