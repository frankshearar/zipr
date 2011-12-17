module Zipr
  class Tree
    attr_reader :children
    attr_reader :value

    def initialize(value, array)
      @children = array
      @value = value
    end

    def to_s
      if children.empty? then
        @value.inspect
      else
        "#{value.inspect} [#{children.map{|c| c.to_s}.join(", ")}]"
      end
    end

    def ==(obj)
      case obj
        when Tree then value == obj.value and children == obj.children
        else false
      end
    end

    def hash
      (41 * (41 * 1) + value.hash) + children.hash
    end

    def branch?
      !children.empty?
    end

    def zipper
      mknode = -> value,children {
        case value
          when Tree then Tree.new(value.value, children)
          else Tree.new(value, children)
        end
      }

      Zipper.zip_on(self, :branch?, :children, mknode)
    end
  end

  class TaggedTree
    def branch?
      false
    end

    def zipper
      mknode = -> value,children {
        if children.empty? then
          Leaf.new(value)
        else
          Node.new(value.tag, children)
        end
      }

      Zipper.zip_on(self, :branch?, :children, mknode)
    end
  end

  class Node < TaggedTree
    attr_reader :children
    attr_reader :tag

    def initialize(tag, children)
      @tag = tag
      @children = children
      children.freeze
      tag.freeze
      freeze
    end

    def ==(obj)
      case obj
        when Node then @tag == obj.tag and @children == obj.children
        else false
      end
    end

    def hash
      (41 * (41 * 1) + tag.hash) + children.hash
    end

    def branch?
      true
    end

    def depth
      max_subtree_depth = children.map {|c| c.depth}.max
      (max_subtree_depth || 0) + 1
    end

    def size
      subtree_size = children.map {|c| c.size}.reduce(:+)
      (subtree_size || 0) + 1
    end
  end

  class Leaf < TaggedTree
    attr_reader :value

    def self.value(obj)
      Leaf.new(obj)
    end

    def initialize(value)
      @value = value
      value.freeze
      freeze
    end

    def ==(obj)
      case obj
        when Leaf then @value == obj.value
        else false
      end
    end

    def hash
      @value.hash
    end

    def depth
      1
    end

    def size
      1
    end
  end

  class EmptyTree < TaggedTree
    def ==(obj)
      case obj
        when EmptyTree then true
        else false
      end
    end

    def hash
      0
    end

    def depth
      0
    end

    def size
      0
    end
  end
end
