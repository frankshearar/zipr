[![Build Status](https://secure.travis-ci.org/frankshearar/zipr.png?branch=master)](http://travis-ci.org/frankshearar/zipr) [![Coverage Status](https://coveralls.io/repos/frankshearar/zipr/badge.png?branch=master)](https://coveralls.io/r/frankshearar/zipr)

A [Huet-style zipper](http://www.st.cs.uni-saarland.de/edu/seminare/2005/advanced-fp/docs/huet-zipper.pdf) written in Ruby.

Basic architecture
------------------

Zipr supplies two ways of navigating through a structure. "Safe navigation" methods are named safe\_foo, and uses the `Either` monad: attempting to move off the structure returns a `Left` indicating the error; otherwise, we get a `Right` containing a `Zipper` on the next position. "Unsafe navigation" methods are just like the safe ones, only without a "safe\_" prefix.

Unsafe navigation is best suited for when you know the precise path to some node, allowing for terse code:

    t = Tree.new(1, [Tree.new(2, []), Tree.new(3, [])])
    z = t.zipper.down.down
    z.value.should == 2

Safe navigation is best suited for exploring a structure whose structure you don't know. To safely navigate to the rightmost grandchild of a node (or stay in the current location if there's no such node):

    z = a_node_in_some_arbitrary_tree.zipper
    z.safe_down.either(->l{
                         l.safe_right.either(->r{
                                               r.safe_down.either(->rl{
                                                                    rl.safe_right(->rr{rr},
                                                                                  ->error{z})
                                                                  },
                                                                  ->error{z}),
                                             },
                                             ->error{z}),
                       },
                       ->error{z})

A bit of a mouthful, but consider that we have handled every possible case: no left child, no right child, no left-of-right grandchild, and no right-of-right grandchild. If the node has a right-of-right grandchild, we will have a Right whose :value will be the desired node. If not, we will have a Left whose :error will tell us what went wrong. (By using `->error{[error, z]}` we could tell the caller which node was missing.)

When we create the zipper, we give it:

1. a value in the structure
2. a context (if we're starting navigation this will be a RootContext).
3. a trio of behaviours describing
    1. whether a node has children
    2. what those children are
    3. how to make a fresh node

Those three behaviours may be a Proc or a Symbol naming a method:

    t = Tree.new(2, [Tree.new(1, []), Tree.new(3, [])])
    mknode = ->value, children {Tree.new(value, children)}
    Zipper.new(t, RootContext.new, ->x{!x.children.empty?}, :children, mknode)

The sample structures provide their own convenience `:zipper` methods.

Advanced features
-----------------
Zipr supplies many higher-order features. Not only may you arbitrarily navigate a structure, Zipr also supplies a `PreOrderTraversal` (unsafe in the presence of cycles). Zipr uses this traversal to `fold` or `map` arbitrary structures. In particular, `map` returns the same kind of structure: if you have some kind of custom tree, `map` will return that same kind of tree. This is unlike `Enumerable`'s `map`, which flattens the structure into an `Array`.

Licence
-------

Copyright (C) 2011-2013 by Frank Shearar

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.