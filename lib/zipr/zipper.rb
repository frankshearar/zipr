require 'zipr/either'

module Zipr
  class Zipper
    attr_reader :value
    attr_reader :context

    def self.zip_on(node, branch_fn, children_fn, mknode_fn)
      Zipper.new(node, RootContext.new, branch_fn, children_fn, mknode_fn)
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

    def down
      v = safe_down
      case v
        when Left then raise ZipperNavigationError.new(v.error)
        when Right then v.value
      end
    end

    def up
      v = safe_up
      case v
        when Left then raise ZipperNavigationError.new(v.error)
        when Right then v.value
      end
    end

    # Return the possibly mutated version of the structure.
    def root
      @value
    end

    # Move the context to the first (leftmost) child node.
    def safe_down
      if branch?(value) then
        Right.new(Zipper.new(children(value).first,
                             Context.new(context,
                                         value,
                                         [],
                                         children(value).drop(1),
                                         context.visited_nodes + [value],
                                         false),
                             @branch,
                             @children,
                             @mknode))
      else
        Left.new(:down_at_leaf)
      end
    end

    def safe_up
      if context.root? then
        Left.new(:up_at_root)
      else
        Right.new(Zipper.new(context.visited_nodes.last,
                             context.path,
                             @branch,
                             @children,
                             @mknode))
      end
    end
  end

  # The context of a value in a structure.
  class BaseContext
    attr_reader :left_nodes
    attr_reader :path
    attr_reader :right_nodes
    attr_reader :value
    attr_reader :visited_nodes

    def changed?
      raise ":changed? not defined for #{self.class.name}"
    end

    def root?
      false
    end
  end

  # A one-hole context in some arbitrary hierarchical structure
  class Context < BaseContext
    def initialize(path, value, left_nodes, right_nodes, visited_nodes, changed)
      @path = path
      @value = value
      @left_nodes = left_nodes
      @right_nodes = right_nodes
      @visited_nodes = visited_nodes
      @changed = changed
    end

    def changed?
      @changed
    end
  end

  # Marker class, indicating that we've not navigated anywhere or mutated
  # anything yet.
  class RootContext < BaseContext
    def changed?
      false
    end

    def left_nodes
      []
    end

    def path
      #This lets us avoid unsightly conditionals in the zipper: the path of no
      # path is no path. Zipping up isn't a problem because :safe_up checks
      # :root?.
      self
    end

    def root?
      true
    end

    def right_nodes
      []
    end

    def visited_nodes
      []
    end
  end

  class UnsupportedOperation < Exception
    attr_reader :method_name
    attr_reader :parameter

    def initialize(method_name, param)
      @method_name = method_name
      @parameter = param
    end

    def to_s
      "Method #{method_name.inspect} called with unsupported parameter type #{parameter.class.name}"
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
