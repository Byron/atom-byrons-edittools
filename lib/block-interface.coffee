
# A type to allow seeing any document as a sequence of hierarchical blocks.
#
# The Block serves as cursor through these blocks, which in turn can only provide
# adjecency information about its neighbours on the left and right.
#
# However, the traversal order provided here is based on how they strictly appear
# in the document. From that point of view, the Block behaves much like a lexer,
# where tokens are blocks.
class BlockInterface
  subclass_implementation_needed = () -> throw new Error('to be implemented in subclass')

  # Returns a new Block object in the given direction, or null if no such
  # block exists. The only reason to return null is if there is no block
  # to the left or right, such as if you are at the beginning of the document
  # (*no block to the left*), or at the end (*no block to the right*).
  adjecentTo: (direction) -> subclass_implementation_needed()

  # Returns the depth of the Block within the tree.
  # It is relative, but has to be consistent.
  # Thus the Block starting the traversal may have any depth, as long as its direct
  # children have depth() + 1, parents have depth() - 1, and siblings have depth()
  # The caller will assume that Blocks with equal depth have the same parent.
  # If this is not actually the case, you have to provide Blocks with depth increments/decrements
  # of 1, which effectively guides the caller along the tree. Otherwise it has no way
  # of knowing the actual parent of a block.
  depth: () -> subclass_implementation_needed()


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

Direction =
  right: 'right'
  left: 'left'

Relation =
  directChild: 'directChild',
  directParent: 'directParent',
  sibling: 'sibling'


module.exports = {Direction, Relation, BlockInterface, BlockCache}
