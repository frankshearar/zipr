require 'rantly/property'
require 'zipr/test-trees'

class Rantly
  def any
    choose(integer, string, boolean)
  end

  def max_subtrees
    10
  end

  def tree(n = self.size)
    if (n <= 0) then
      Zipr::EmptyTree.new
    elsif (n == 1) then
      Zipr::Leaf.value(any)
    else
      num_subtrees = integer(0..max_subtrees)
      subtrees = []
      sz = n
      while (sz > 0) do
        t = tree(integer(0..(n - 1)))
        subtrees << t
        sz -= t.size
      end
      Zipr::Node.new(any, subtrees)
    end
  end
end
