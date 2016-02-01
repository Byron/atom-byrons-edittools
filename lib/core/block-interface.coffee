
# A type to allow seeing any document as a sequence of hierarchical blocks.
#
# The Block serves as cursor through these blocks, which in turn can only provide
# adjecency information about its neighbours on the previous and next.
#
# However, the traversal order provided here is based on how they strictly appear
# in the document. From that point of view, the Block behaves much like a lexer,
# where tokens are blocks.
class BlockInterface
  subclass_implementation_needed = () -> throw new Error('to be implemented in subclass')

  # Returns a new Block object in the given direction, or null if no such
  # block exists. The only reason to return null is if there is no block
  # to the previous or next, such as if you are at the beginning of the document
  # (*no block to the previous*), or at the end (*no block to the next*).
  at: (direction) -> subclass_implementation_needed()

  # Returns the depth of the Block within the tree.
  # It is relative, but has to be consistent.
  # Thus the Block starting the traversal may have any depth, as long as its direct
  # children have depth() + 1, parents have depth() - 1, and siblings have depth()
  # The caller will assume that Blocks with equal depth have the same parent.
  # If this is not actually the case, you have to provide Blocks with depth increments/decrements
  # of 1, which effectively guides the caller along the tree. Otherwise it has no way
  # of knowing the actual parent of a block.
  depth: () -> subclass_implementation_needed()

TraversalDirection =
  next: 'next'
  previous: 'previous'
{next, previous} = TraversalDirection

oppositeOf = (direction) ->
  switch direction
    when previous then next
    when next then previous
    else throw new Error("Unknown direction: #{direction}")

module.exports = {TraversalDirection, BlockInterface, oppositeOf}