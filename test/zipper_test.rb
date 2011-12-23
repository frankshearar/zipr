require 'zipr/zipper'
require 'zipr/test-trees'
require 'rantly/property'
require 'rspec'
require 'zipr/rantly-extensions'

module Zipr
  describe Zipper do
    it "should allow zipping on a structure" do
      Zipper.zip_on(Leaf.new(1), ->x{false}, ->x{[]}, ->x,kids{nil}).should_not be_nil
    end

    it "should allow zipping over an arbitrary structure" do
      z = Zipper.zip_on([1, [2, 3], 4], ->x{x.kind_of? Array}, ->x{x}, ->x,kids{ :as_yet_unused })
      z1 = z.down
      z1.value.should == 1
      z2 = z1.right
      z2.value.should == [2, 3]
      z3 = z2.down
      z3.value.should == 2
      z3.safe_down.should be_left
    end

    it "should record an error going down on a leaf" do
      l = Leaf.new(1)
      loc = l.zipper
      z = loc.safe_down
      z.should be_left
      z.error.error.should == :down_at_leaf
      z.error.location.should == loc
    end

    it "should allow down on a branch point" do
      t = Node.new(:unimportant, [Leaf.new(1)])
      z = t.zipper.safe_down
      z.should be_right
      new_zipper = z.value
      new_zipper.class.should == Zipper
      new_zipper.value.class.should == Leaf
      new_zipper.value.value.should == 1
    end

    it "should provide an 'unsafe' down" do
      t = Node.new(:unimportant, [Leaf.new(1)])
      z = t.zipper.down
      z.class.should == Zipper
      z.value.class.should == Leaf
      z.value.value.should == 1
    end

    it "should have unsafe down fail on a leaf" do
      ->{
        Leaf.new(1).zipper.down
      }.should raise_error(ZipperNavigationError) { |e|
        e.to_s.should == "Navigation error - :down_at_leaf"
      }
    end

    it "should forbid up at the root node" do
      l = Leaf.new(1)
      loc = l.zipper
      z = loc.safe_up
      z.should be_left
      z.error.error.should == :up_at_root
      z.error.location.should == loc
    end

    it "should have up move to the parent node" do
      t = Node.new(1, [Leaf.new(1)])
      z = t.zipper.down.safe_up
      z.should be_right
      new_zipper = z.value
      new_zipper.value.class.should == Node
      new_zipper.value.tag.should == 1
    end

    it "should have down, down, up, up be an idempotent navigation" do
      t = Node.new(:root, [Node.new(:child, [Leaf.new(:grandchild)])])
      t.zipper.down.down.up.up.value.should == t
    end

    it "should have down then up be an idempotent navigation" do
      property_of {
        t = sized(50) { tree }
        guard(t.depth > 1)
        t
      }.check {|t|
        t.zipper.down.up.value.should == t
      }
    end

    it "should have unsafe up on the root node fail" do
      ->{
        Leaf.new(1).zipper.up
      }.should raise_error(ZipperNavigationError) { |e|
        e.to_s.should == "Navigation error - :up_at_root"
      }
    end

    it "should have left fail on a leftmost child" do
      t = Node.new(1, [Leaf.new(1)])
      loc = t.zipper.down
      z = loc.safe_left
      z.should be_left
      z.error.error.should == :left_at_leftmost
      z.error.location.should == loc
    end

    it "should have left fail on root node" do
      t = Node.new(2, [Leaf.new(1), Leaf.new(2)])
      n = t.zipper
      z = n.safe_left
      z.should be_left
      z.error.error.should == :left_at_root
      z.error.location.should == n
    end

    it "should have unsafe left fail on root node" do
      t = Node.new(2, [Leaf.new(1), Leaf.new(2)])
      ->{
        t.zipper.left
      }.should raise_error(ZipperNavigationError) { |e|
        e.to_s.should == "Navigation error - :left_at_root"
      }
    end

    it "should have left move to the next left sibling" do
      t = Node.new(2, [Leaf.new(1), Leaf.new(2)])
      z = t.zipper.down.right.safe_left
      z.should be_right
      new_zipper = z.value
      new_zipper.value.class.should == Leaf
      new_zipper.value.value.should == 1
    end

    it "should have left preserve the parent node backpointer" do
      t = Node.new(:root, (1..5).map {|i| Leaf.new(i)})
      z = t.zipper.down.right.left
      z.value.should == Leaf.new(1)
      z.context.parent_node.should == t
    end

    it "should have unsafe left fail on a leftmost child" do
      t = Node.new(1, [Leaf.new(1)])
      ->{
        z = t.zipper.down.left
      }.should raise_error(ZipperNavigationError) { |e|
        e.to_s.should == "Navigation error - :left_at_leftmost"
      }
    end

    it "should have right move to the next right sibling" do
      t = Node.new(2, [Leaf.new(1), Leaf.new(2)])
      z = t.zipper.down.safe_right
      z.should be_right
      new_zipper = z.value
      new_zipper.class.should == Zipper
      new_zipper.value.class.should == Leaf
      new_zipper.value.value.should == 2
    end

    it "should have right preserve the parent node backpointer" do
      t = Node.new(:root, (1..5).map {|i| Leaf.new(i)})
      z = t.zipper.down.right
      z.value.should == Leaf.new(2)
      z.context.parent_node.should == t
    end

    it "should have right fail on root node" do
      t = Node.new(2, [Leaf.new(1), Leaf.new(2)])
      n = t.zipper
      z = n.safe_right
      z.should be_left
      z.error.error.should == :right_at_root
      z.error.location.should == n
    end

    it "should have unsafe right fail on root node" do
      t = Node.new(2, [Leaf.new(1), Leaf.new(2)])
      ->{
        t.zipper.right
      }.should raise_error(ZipperNavigationError) { |e|
        e.to_s.should == "Navigation error - :right_at_root"
      }
    end

    it "should have unsafe right move to the next right sibling" do
      t = Node.new(2, [Leaf.new(1), Leaf.new(2)])
      z = t.zipper.down.right
      z.class.should == Zipper
      z.value.class.should == Leaf
      z.value.value.should == 2
    end

    it "should have right fail on the rightmost child" do
      t = Node.new(1, [Leaf.new(1)])
      loc = t.zipper.down
      z = loc.safe_right
      z.should be_left
      z.error.error.should == :right_at_rightmost
      z.error.location.should == loc
    end

    it "should have unsafe right fail on the rightmost child" do
      t = Node.new(1, [Leaf.new(1)])
      z = t.zipper.down
      ->{
        z.right
      }.should raise_error(ZipperNavigationError) { |e|
        e.to_s.should == "Navigation error - :right_at_rightmost"
      }
    end

    it "should have right then left be an idempotent navigation" do
      property_of {
        t = sized(50) { tree }
        guard(t.branch?)
        guard(t.children.length > 1)
        t
      }.check {|t|
        z = t.zipper.down
        z.right.left.value.should == z.value
      }
    end

    it "should have left then right be an idempotent navigation" do
      property_of {
        t = sized(5) { tree }
        guard(t.branch?)
        guard(t.children.length > 1)
        t
      }.check {|t|
        z = t.zipper.down.right
        z.left.right.value.should == z.value
      }
    end

    it "should have rightmost move immediately to the rightmost node" do
      t = Node.new(:root, (1..5).map {|i| Leaf.new(i)})
      z = t.zipper.down.safe_rightmost
      z.should be_right
      new_zipper = z.value
      new_zipper.value.should == Leaf.new(5)
    end

    it "should have rightmost not forget about the current node" do
      t = Node.new(:root, (1..5).map {|i| Leaf.new(i)})
      z = t.zipper.down.right.right.right.rightmost
      z.value.should == Leaf.new(5)
      z.left.value.should == Leaf.new(4)
    end

    it "should have rightmost preserve the parent node backpointer" do
      t = Node.new(:root, (1..5).map {|i| Leaf.new(i)})
      z = t.zipper.down.rightmost
      z.value.should == Leaf.new(5)
      z.context.parent_node.should == t
      z.left.value.should == Leaf.new(4)
    end

    it "should have rightmost not move when at the rightmost node" do
      t = Node.new(:root, (1..5).map {|i| Leaf.new(i)})
      z = t.zipper.down.rightmost.safe_rightmost
      z.should be_right
      new_zipper = z.value
      new_zipper.value.should == Leaf.new(5)
    end

    it "should have rightmost work when there's only one child" do
      t = Node.new(:root, [Leaf.new(1)])
      z = t.zipper.down.safe_rightmost
      z.should be_right
      new_zipper = z.value
      new_zipper.value.should == Leaf.new(1)
    end

    it "should have leftmost move immediately to the leftmost node" do
      t = Node.new(:root, (1..5).map {|i| Leaf.new(i)})
      z = t.zipper.down.rightmost.safe_leftmost
      z.should be_right
      new_zipper = z.value
      new_zipper.value.should == Leaf.new(1)
    end

    it "should have leftmost not forget about the current node" do
      t = Node.new(:root, (1..5).map {|i| Leaf.new(i)})
      z = t.zipper.down.right.leftmost
      z.value.should == Leaf.new(1)
      z.right.value.should == Leaf.new(2)
    end

    it "should have leftmost preserve the parent node backpointer" do
      t = Node.new(:root, (1..5).map {|i| Leaf.new(i)})
      z = t.zipper.down.rightmost.leftmost
      z.value.should == Leaf.new(1)
      z.context.parent_node.should == t
    end

    it "should have leftmost not move when at the leftmost node" do
      t = Node.new(:root, (1..5).map {|i| Leaf.new(i)})
      z = t.zipper.down.safe_leftmost
      z.should be_right
      new_zipper = z.value
      new_zipper.value.should == Leaf.new(1)
    end

    it "should have leftmost work when there's only one child" do
      t = Node.new(:root, [Leaf.new(1)])
      z = t.zipper.down.safe_leftmost
      z.should be_right
      new_zipper = z.value
      new_zipper.value.should == Leaf.new(1)
    end

    it "should allow replacing of a root node" do
      t = Tree.new(1, [])
      z = t.zipper.safe_replace(Tree.new(2, []))
      z.should be_right
      new_zipper = z.value
      new_zipper.class.should == Zipper
      new_zipper.value.should == Tree.new(2, [])
      new_zipper.root.should == Tree.new(2, [])
    end

    it "should allow 'unsafe' replacing of a root node" do
      t = Tree.new(1, [])
      replacement = Tree.new(2, [])
      z = t.zipper.replace(replacement)
      z.class.should == Zipper
      z.value.should == replacement
      z.root.should == replacement
    end

    it "should allow replacing of a child node" do
      t = Tree.new(1, [Tree.new(2, [])])
      z = t.zipper.down.safe_replace(Tree.new(3, []))
      z.should be_right
      new_zipper = z.value
      new_zipper.root.should == Tree.new(1, [Tree.new(3, [])])
    end

    it "should move over the replaced node" do
      t = Node.new(:root, [Node.new(:original, [Leaf.new(1), Leaf.new(2)])])
      z = t.zipper.down.replace(Node.new(:new, [Leaf.new(3)]))
      z.value.tag.should == :new
      z.down.value.should == Leaf.new(3)
    end

    it "should not bother replacing a node with an == node" do
      original = Leaf.new(1)
      t = Node.new(:root, [Node.new(:original, [original, Leaf.new(2)])])
      z = t.zipper.down.down.replace(Leaf.new(1))
      z.value.should be_equal(original)
    end

    it "should allow editing of a node" do
      t = Node.new(1, [Leaf.new(1)])
      z = t.zipper.down.change {|n| Leaf.new(n.value + 1)}
      z.root.should == Node.new(1, [Leaf.new(2)])
    end

    it "should allow inserting a child node on a leaf node" do
      t = Tree.new(1, [])
      z = t.zipper.insert_child(Tree.new(2, []))
      z.root.should == Tree.new(1, [Tree.new(2, [])])
    end

    it "should insert a child as the leftmost child" do
      t = Tree.new(1, [Tree.new(2, [])])
      z = t.zipper.insert_child(Tree.new(3, [])).insert_child(Tree.new(4, []))
      z.root.should == Tree.new(1, [Tree.new(4, []), Tree.new(3, []), Tree.new(2, [])])
    end

    it "should allow inserting a child as the rightmost child" do
      t = Tree.new(1, [Tree.new(2, [])])
      z = t.zipper.append_child(Tree.new(3, [])).append_child(Tree.new(4, []))
      z.root.should == Tree.new(1, [Tree.new(2, []), Tree.new(3, []), Tree.new(4, [])])
    end

    it "should allow inserting a sibling to the left" do
      t = Tree.new(1, [Tree.new(2, [])])
      z = t.zipper.down.insert_left(Tree.new(3, [Tree.new(4, [])])).insert_left(Tree.new(5, []))
      z.root.should == Tree.new(1, [Tree.new(3, [Tree.new(4, [])]), Tree.new(5, []), Tree.new(2, [])])
    end

    it "should allow inserting a sibling to the right" do
      t = Tree.new(1, [Tree.new(2, [])])
      z = t.zipper.down.insert_right(Tree.new(3, [Tree.new(4, [])])).insert_right(Tree.new(5, []))
      z.root.should == Tree.new(1, [Tree.new(2, []), Tree.new(5, []), Tree.new(3, [Tree.new(4, [])])])
    end

    it "should allow the bulk insert of a number of children to the left" do
      t = Tree.new(1, [Tree.new(2, [])])
      z = t.zipper.insert_all((3..5).map {|i| Tree.new(i, [])})
      z.root.should == Tree.new(1, [Tree.new(3, []), Tree.new(4, []), Tree.new(5, []), Tree.new(2, [])])
    end

    it "should allow the bulk insert of a number of children to the right" do
      t = Tree.new(1, [Tree.new(2, [])])
      z = t.zipper.append_all((3..5).map {|i| Tree.new(i, [])})
      z.root.should == Tree.new(1, [Tree.new(2, []), Tree.new(3, []), Tree.new(4, []), Tree.new(5, [])])
    end

    it "should root on a trivial structure" do
      t = Leaf.new(1)
      t.zipper.root.should == t
    end

    it "should root on a deep structure" do
      t = Node.new(:root, [Node.new(:left, [Leaf.new(1)]), Node.new(:right, [Leaf.new(2)])])
      t.zipper.down.down.root.should == t
    end

    it "should root on an altered structure" do
      t = Tree.new(2, [Tree.new(1, []), Tree.new(3, [])])
      z = t.zipper.down.replace(Tree.new(0, []))
      z.root.should == Tree.new(2, [Tree.new(0, []), Tree.new(3, [])])
    end

    it "should allow the deleting of solitary children" do
      t = Tree.new(1, [Tree.new(2, [])])
      z = t.zipper.down.remove
      z.root.should == Tree.new(1, [])
    end

    it "should not allow the deleting of an entire structure" do
      t = Tree.new(1, [Tree.new(2, [])])
      loc = t.zipper
      z = loc.safe_remove
      z.should be_left
      z.error.error.should == :remove_at_root
      z.error.location.should == loc
    end

    it "should have unsafe delete at root fail" do
      ->{
        Tree.new(1, []).zipper.remove
      }.should raise_error(ZipperNavigationError) { |e|
        e.to_s.should == "Navigation error - :remove_at_root"
      }
    end

    it "should move to the left sibling after deleting a node (1)" do
      t = Tree.new(1, [Tree.new(2, []), Tree.new(3, [])])
      z = t.zipper.down.rightmost.remove
      z.value.should == Tree.new(2, [])
      z.root.should == Tree.new(1, [Tree.new(2, [])])
    end

    it "should move to the left sibling after deleting a node (2)" do
      t = Tree.new(1, [Tree.new(2, []), Tree.new(3, [])])
      z = t.zipper.down.right.remove
      z.value.should == Tree.new(2, [])
      z.root.should == Tree.new(1, [Tree.new(2, [])])
    end

    it "should move to the parent after deleting the leftmost child" do
      t = Tree.new(1, [Tree.new(2, []), Tree.new(3, [])])
      z = t.zipper.down.remove
      z.value.value.should == 1
      z.root.should == Tree.new(1, [Tree.new(3, [])])
    end

    it "should move to the parent after deleting the leftmost child within a subtree" do
      t = Tree.new(1, [Tree.new(2, [Tree.new(4, [])]), Tree.new(3, [])])
      z = t.zipper.down.down.remove
      z.value.value.should == 2
      z.root.should == Tree.new(1, [Tree.new(2, []), Tree.new(3, [])])
    end

    it "should return the original structure for any non-mutating navigation" do
      property_of {
        sized(50) { tree }
      }.check { |tree|
        trav = tree.zipper.map { |n| n }
        trav.root.equal?(tree).should be_true
      }
    end

    it "should permit :collect as an alias of :map" do
      t = Leaf.new(1)
      t.zipper.collect {|n| n}.root.should == t.zipper.map {|n| n}.root
    end

    it "should share as much of the original structure as possible" do
      o = Object.new
      original = Node.new(o, [Leaf.new(1), Leaf.new(2)])
      new = original.zipper.down.replace(Leaf.new(3)).root
      new.should == Node.new(o, [Leaf.new(3), Leaf.new(2)])

      original.tag.should be_equal(new.tag)
      original.children[1].should be_equal(new.children[1])
    end

    it "should permit the folding of a structure according to a given block" do
      t = Node.new(:root, [Node.new(:left_subchild, [Leaf.new(1)]), Leaf.new(2)])
      t.zipper.fold(0) { |sum, node|
        sum + case node
                when Node then 0
                when Leaf then node.value
              end
      }.should == 3
    end

    it "should permit the folding of a structure according to a given " + \
    "block with a given traversal" do
      t = Node.new(:root, [Node.new(:left_subchild, [Leaf.new(1)]), Leaf.new(2)])
      z = t.zipper
      # TODO: Clearly, this API is less than optimal, with the mention of z
      # twice: that's asking for an error like
      # z.fold(0, PreOrderTraversal.new(y)) {}
      z.fold(0, PreOrderTraversal.new(z)) { |sum, node|
        sum + case node
                when Node then 0
                when Leaf then node.value
              end
      }.should == 3
    end
  end

  describe PreOrderTraversal do
    it "should process all nodes in a pre-order fashion" do
      tree = Tree.new(1, [Tree.new(2, [Tree.new(3, [])]),
                          Tree.new(4, [Tree.new(5, []),
                                       Tree.new(6, [])])])
      t = PreOrderTraversal.new(tree.zipper)
      answers = []
      t.each { |value|
        answers << value.value
      }
      answers.should == [1, 2, 3, 4, 5, 6]
    end

    it "should have map produce a structure of the same shape" do
      tree = Node.new(2, [Leaf.new(1), Leaf.new(2)])
      t = PreOrderTraversal.new(tree.zipper)
      new_t = t.map { |node|
        case node
          when Node then Node.new(node.tag * 3, node.children)
          when Leaf then Leaf.new(node.value * 2)
        end
      }
      new_t.class.should == Zipper
      new_t.root.should == Node.new(6, [Leaf.new(2), Leaf.new(4)])
    end

    it "should permit the folding of a structure according to a given block (1)" do
      t = Node.new(:root, [Node.new(:left_subchild, [Leaf.new(1)]), Leaf.new(2)])
      PreOrderTraversal.new(t.zipper).fold(0) { |sum, node|
        sum + case node
                when Node then 0
                when Leaf then node.value
              end
      }.should == 3
    end

    it "should permit the folding of a structure according to a given block (2)" do
      tree = Tree.new(1, [Tree.new(2, [Tree.new(3, [])]),
                          Tree.new(4, [Tree.new(5, []),
                                       Tree.new(6, [])])])
      PreOrderTraversal.new(tree.zipper).fold(0) { |sum, node|
        [sum,
         if node.children.empty? then 1 else 1 + sum end].max
      }.should == 3
    end
  end
end

