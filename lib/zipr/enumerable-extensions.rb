require 'zipr/zipper'

module Enumerable
  def zipper
    mknode = -> value, children {
      # value is the original thing; children is the
      # possibly altered sequence of elements.
      children
    }

    Zipr::Zipper.zip_on(self,
                        -> x {x.kind_of?(Enumerable)},
                        -> x {x}, # Children are the elements
                        mknode)
  end
end
