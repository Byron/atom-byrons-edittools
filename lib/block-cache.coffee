# Uses an implementation of a BlockInterface to keep track of the hierarchy
# traversed so far.
#
# Blocks have ancestors (parents), descendants (children), and those who are
# adjecent to them (siblings) - they form a tree.
#
# The cache abstracts and traversal so far, making it more convenient to work
# with the BlockInterface.
#
# It owns the blocks it keeps for you, and modifies them to keep track of their
# relationships while allowing fast traversal.
#
# It's worth noting that the root of the tree will change as the traversal proceeds,
# as we don't expect it to begin top-most. After all, we discover the document
# as we traverse it.
class BlockCache
  constructor: (firstBlock) ->
    @$cursor = firstBlock
    @$root = $$parent: null, $$children: [firstBlock]

module.exports = BlockCache
