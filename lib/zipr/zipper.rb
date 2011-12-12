require 'zipr/either'
require 'zipr/unsupported-operation'

module Zipr
  # A zipper is a data structure consisting of a value (representing some place
  # in some data structure) and a context (the rest of the structure, or the
  # hole into which you plug the value to have the original structure once more).
  #
  # You may think of a zipper as a suspended walk - that is, as a means of
  # navigating and mutating a data structure such that at any point you can store
  # your traversal/mutation and go do something else.
  #
  # You may also think of a zipper, equivalently, as a set of change records, or
  # a monad or computation builder:
  # "Take this structure, move down then left. Replace that node with this node.
  # Then go right, and insert this node. Oh, and delete the leftmost child."
  #
  # This zipper provides both "safe" and "unsafe" navigations/mutations. A safe
  # operation is one that returns either a Right containing a new zipper
  # representing that operation if the action makes sense on the current node, or
  # a Left if the action is impossible (for instance, trying to move down on a
  # leaf node of a tree). An unsafe operation simply raises a
  # ZipperNavigationError in the event of an impossible action. Unsafe operations
  # provide a terser navigation, at the risk of raising an exception. A chain of
  # safe operations simply returns the first error encountered.
  class Zipper
    attr_reader :value
    attr_reader :context

    def self.zip_on(node, branch_fn, children_fn, mknode_fn)
      Zipper.new(node, Context.root_context, branch_fn, children_fn, mknode_fn)
    end

    def initialize(value, context, branch, children, mknode)
      @value = value
      @context = context

      @branch = branch
      @children = children
      @mknode = mknode
    end

    # Is this node a node that may have children? If given a Symbol, send that
    # message to the node. Otherwise, return the result of invoking the unary
    # Proc with the node.
    def branch?(node)
      case @branch
        when Symbol then node.send(@branch)
        when Proc then @branch.call(node)
      else
        raise UnsupportedOperation.new(:branch?, node)
      end
    end

    # What children does this node have? If given a Symbol, send that message
    # to the node. Otherwise, return the result of invoking the unary Proc with
    # the node.
    def children(node)
      case @children
        when Symbol then node.send(@children)
        when Proc then @children.call(node)
      else
        raise UnsupportedOperation.new(:children, node)
      end
    end

    # Given a parent node and some children, construct a new node.
    def mknode(value, children)
      @mknode.call(value, children)
    end

    def append_all(array_of_new_nodes)
      safe_append_all(array_of_new_nodes).value
    end

    def append_child(new_node)
      safe_append_child(new_node).value
    end

    def change(&block)
      safe_change(&block).value
    end

    def down
      safe_down.either(->r{r.value},
                       ->l{raise ZipperNavigationError.new(l.error)})
    end

    def left
      safe_left.either(->r{r.value},
                       ->l{raise ZipperNavigationError.new(l.error)})
    end

    def leftmost
      safe_leftmost.value
    end

    def right
      safe_right.either(->r{r.value},
                        ->l{raise ZipperNavigationError.new(l.error)})
    end

    def rightmost
      safe_rightmost.value
    end

    def up
      safe_up.either(->r{r.value},
                     ->l{raise ZipperNavigationError.new(l.error)})
    end

    def insert_child(new_node)
      safe_insert_child(new_node).value
    end

    def insert_all(array_of_new_nodes)
      safe_insert_all(array_of_new_nodes).value
    end

    def insert_left(new_node)
      safe_insert_left(new_node).value
    end

    def insert_right(new_node)
      safe_insert_right(new_node).value
    end

    def replace(new_node)
      safe_replace(new_node).value
    end

    # Return the possibly mutated version of the structure.
    def root
      if context.root? then
        @value
      else
        if context.changed? then
          __changed_up.__changed_root
        else
          up.root
        end
      end
    end

    # Maintaining the current focus, add a new right-most child.
    def safe_append_all(array_of_new_nodes)
      safe_replace(mknode(value, children(value) + array_of_new_nodes))
    end

    # Maintaining the current focus, add a new right-most child.
    def safe_append_child(new_node)
      safe_replace(mknode(value, children(value) + [new_node]))
    end

    # Replace the current focus with the result of calling some unary function
    # with the current focus.
    def safe_change(&block)
      safe_replace(block.call(value))
    end

    # Maintaining the current focus, add a new left-most child.
    def safe_insert_child(new_node)
      safe_replace(mknode(value, [new_node] + children(value)))
    end

    # Maintaining the current focus, add an array of new children, in order, on
    # the left of the current children
    def safe_insert_all(array_of_new_nodes)
      safe_replace(mknode(value, array_of_new_nodes + children(value)))
    end

    # Maintaining the current focus, add a new sibling to the left.
    def safe_insert_left(new_node)
      Right.new(new_zipper(value,
                           Context.new(context.path,
                                       context.parent_node,
                                       context.left_nodes + [new_node],
                                       context.right_nodes,
                                       context.visited_nodes,
                                       true)))
    end

    # Maintaining the current focus, add a new sibling to the right.
    def safe_insert_right(new_node)
      Right.new(new_zipper(value,
                           Context.new(context.path,
                                       context.parent_node,
                                       context.left_nodes,
                                       [new_node] + context.right_nodes,
                                       context.visited_nodes,
                                       true)))
    end

    # Move the context to the first (leftmost) child node.
    # Return a Left if the current focus has no children.
    def safe_down
      if branch?(value) then
        Right.new(new_zipper(children(value).first,
                             Context.new(context,
                                         value,
                                         [],
                                         children(value).drop(1),
                                         context.visited_nodes + [value],
                                         false)))
      else
        Left.new(:down_at_leaf)
      end
    end

    # Move the context to the sibling to the left.
    # Return a Left is the current focus is the leftmost sibling.
    def safe_left
      if context.root? then
        Left.new(:left_at_root)
      elsif context.left_nodes.empty? then
        Left.new(:left_at_leftmost)
      else
        Right.new(new_zipper(context.left_nodes.last,
                             Context.new(context,
                                         context.parent_node,
                                         context.left_nodes[0..-2],
                                         [value] + context.right_nodes,
                                         context.visited_nodes + [value],
                                         false)))
      end
    end

    # Immediately move to the leftmost sibling (or stay in place, if already
    # leftmost). Visit the intermediate nodes "in bulk".
    #
    # This operation can't fail because there must be at least this node, even
    # with no siblings: you can't go down when you're on a node without children.
    def safe_leftmost
      if context.left_nodes == [] then
        Right.new(self)
      else
        all_but_leftmost = context.left_nodes.drop(1)
        Right.new(new_zipper(context.left_nodes.first,
                             Context.new(context,
                                         context.parent_node,
                                         [],
                                         all_but_leftmost + [value] + context.right_nodes,
                                         context.visited_nodes + all_but_leftmost,
                                         false)))
      end
    end

    # Move the context to the sibling to the right.
    # Return a Left is the current focus is the rightmost sibling.
    def safe_right
      if context.root? then
        Left.new(:right_at_root)
      elsif context.right_nodes.empty? then
        Left.new(:right_at_rightmost)
      else
        Right.new(new_zipper(context.right_nodes.first,
                             Context.new(context,
                                         context.parent_node,
                                         context.left_nodes + [value],
                                         context.right_nodes.drop(1),
                                         context.visited_nodes + [value],
                                         false)))
      end
    end

    # Immediately move to the rightmost sibling (or stay in place, if already
    # rightmost). Visit the intermediate nodes "in bulk".
    #
    # This operation can't fail because there must be at least this node, even
    # with no siblings: you can't go down when you're on a node without children.
    def safe_rightmost
      if context.right_nodes == [] then
        Right.new(self)
      else
        all_but_rightmost = context.right_nodes[0..-2]
        Right.new(new_zipper(context.right_nodes.last,
                             Context.new(context,
                                         context.parent_node,
                                         context.left_nodes + [value] + all_but_rightmost,
                                         [],
                                         context.visited_nodes + all_but_rightmost,
                                         false)))
      end
    end

    # Replace the current focus with the given node. You may replace the entire
    # structure if you call this method as your first action on the structure.
    def safe_replace(new_node)
      Right.new(new_zipper(new_node,
                           # This could be a Context or a RootContext
                           context.class.new(context.path,
                                             context.parent_node,
                                             context.left_nodes,
                                             context.right_nodes,
                                             context.visited_nodes,
                                             true)))
    end

    # Zip up one step. If called on the root context - the first action on the
    # structure - return a Left.
    def safe_up
      if context.root? then
        Left.new(:up_at_root)
      else
        Right.new(new_zipper(context.visited_nodes.last,
                             context.path))
      end
    end
    
    # An internal method. Zip up a mutated structure.
    def __changed_root
      if context.root? then
        @value
      else
        __changed_up.__changed_root
      end
    end
    
    def __changed_up
      __safe_changed_up.either(->r{r.value},
                               ->l{raise ZipperNavigationError.new(l.error)})
    end

    # An internal method. The zipper uses this recursion to record in the call
    # stack that the structure has changed.    
    def __safe_changed_up
      if context.root? then
        Left.new(:up_at_root)
      else
        Right.new(new_zipper(mknode(context.parent_node,
                                    context.left_nodes + [value] + context.right_nodes),
                             context.path))
      end
    end

    private
    def new_zipper(value, context)
      Zipper.new(value, context, @branch, @children, @mknode)
    end
  end
  
  # A one-hole context in some arbitrary hierarchical structure
  class Context
    attr_reader :left_nodes
    attr_reader :parent_node
    attr_reader :path
    attr_reader :right_nodes
    attr_reader :visited_nodes

    def self.root_context
      # This lets us avoid unsightly conditionals in the zipper: the path of no
      # path is no path. Zipping up isn't a problem because :safe_up checks
      # :root?.
      if @root_context.nil? then
        @root_context = RootContext.new(self,
                                        :you_should_never_see_the_parent_node_of_a_RootContext,
                                        [],
                                        [],
                                        [],
                                        false)
      end
      @root_context
    end

    def initialize(path, parent_node, left_nodes, right_nodes, visited_nodes, changed)
      @path = path
      @parent_node = parent_node
      @left_nodes = left_nodes
      @right_nodes = right_nodes
      @visited_nodes = visited_nodes
      @changed = changed
    end

    def changed?
      @changed
    end

    def root?
      false
    end
  end

  # Marker class, indicating that we've not navigated anywhere or mutated
  # anything yet.
  class RootContext < Context
    def root?
      true
    end
  end

  class ZipperNavigationError < Exception
    attr_reader :error

    def initialize(symbol)
      @error = symbol
    end

    def to_s
      "Navigation error - #{error.inspect}"
    end
  end
end
