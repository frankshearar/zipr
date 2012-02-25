require 'zipr/zipper'

module Enumerable
  def zipper
    mknode = Proc.new { |value, children|
      # value is the original thing; children is the
      # possibly altered sequence of elements.
      children
    }

    Zipr::Zipper.zip_on(self,
                        Proc.new { |x|
                          # Strings in Ruby 1.8.7 are Enumerable, and we want
                          # to treat them as atoms.
                          x.kind_of?(Enumerable) and not x.kind_of?(String)
                        },
                        Proc.new { |x| x}, # Children are the elements
                        mknode)
  end
end
