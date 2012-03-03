require 'zipr'
require 'zipr/zipper'

module Enumerable
  def zipper
    Zipr::Zipper.zip_on(self,
                     -> x {
                          next false if x.kind_of?(String)
                          x.kind_of?(Enumerable)
                        },
                     -> x { x}, # Children are the elements
                     node_maker)
  end

  def node_maker
    -> value, children {
      # value is the original thing; children is the
      # possibly altered sequence of elements.
      children
    }
  end
end

if sexp_loaded then
  class Sexp
    def node_maker
      -> value, children {
        # value is the original thing; children is the
        # possibly altered sequence of elements.
        Sexp.from_array(children)
      }
    end
  end
end
