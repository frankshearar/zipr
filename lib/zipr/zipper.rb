require 'zipr/either'
require 'zipr/unsupported-operation'

module Zipr
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

    def branch?(node)
      case @branch
        when Symbol then node.send(@branch)
        when Proc then @branch.call(node)
      else
        raise UnsupportedOperation.new(:branch?, node)
      end
    end

    def children(node)
      case @children
        when Symbol then node.send(@children)
        when Proc then @children.call(node)
      else
        raise UnsupportedOperation.new(:children, node)
      end
    end

    def mknode(value, children)
      @mknode.call(value, children)
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

    def right
      safe_right.either(->r{r.value},
                        ->l{raise ZipperNavigationError.new(l.error)})
    end

    def up
      safe_up.either(->r{r.value},
                     ->l{raise ZipperNavigationError.new(l.error)})
    end

    def insert_child(new_node)
      safe_insert_child(new_node).value
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

    def safe_append_child(new_node)
      safe_replace(mknode(value, children(value) + [new_node]))
    end

    def safe_change(&block)
      safe_replace(block.call(value))
    end

    def safe_insert_child(new_node)
      safe_replace(mknode(value, [new_node] + children(value)))
    end

    def safe_insert_left(new_node)
      Right.new(new_zipper(value,
                           Context.new(context.path,
                                       context.parent_node,
                                       context.left_nodes + [new_node],
                                       context.right_nodes,
                                       context.visited_nodes,
                                       true)))
    end

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

    def safe_left
      if context.root? then
        Left.new(:left_at_root)
      elsif context.left_nodes.empty? then
        Left.new(:left_at_leftmost)
      else
        Right.new(new_zipper(context.left_nodes.last,
                             Context.new(context,
                                         value,
                                         context.left_nodes[0..-2],
                                         [value] + context.right_nodes,
                                         context.visited_nodes + [value],
                                         false)))
      end
    end

    def safe_right
      if context.root? then
        Left.new(:right_at_root)
      elsif context.right_nodes.empty? then
        Left.new(:right_at_rightmost)
      else
        Right.new(new_zipper(context.right_nodes.first,
                             Context.new(context,
                                         value,
                                         context.left_nodes + [value],
                                         context.right_nodes.drop(1),
                                         context.visited_nodes + [value],
                                         false)))
      end
    end

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

    def safe_up
      if context.root? then
        Left.new(:up_at_root)
      else
        Right.new(new_zipper(context.visited_nodes.last,
                             context.path))
      end
    end
    
    def __changed_root
      if context.root? then
        @value
      else
        __changed_up.__changed_root
      end
    end
    
    def __changed_up
      v = __safe_changed_up
      case v
        when Left then raise ZipperNavigationError.new(v.error)
        when Right then v.value
      end      
    end
    
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
