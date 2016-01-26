
# A type to allow seeing any document as a sequence of hierarchical blocks.

# The Block serves as cursor through these blocks, which in turn provide
# information about their hierarchical positioning within the documents block tree.
#
# Blocks have ancestors (parents), descendants (children), and those who are
# adjecent to them (siblings)
#
# However, the traversal order provided here is based on how they strictly appear
# in the document. From that point of view, the Block behaves much like a lexer,
# where tokens are blocks.
class BlockInterface
  # Returns a new block in the given direction, or null if no such
  # block exists.
  adjecentTo: (direction) ->
    throw new Error('to be implemented in subclass')

  # Returns the relation this block as to the given one
  relationTo: (block) ->
    throw new Error('to be implemented in subclass')


Direction =
  right: 'right'
  left: 'left'

Relation =
  directChild: 'directChild',
  directParent: 'directParent',
  sibling: 'sibling'

module.exports = {Direction, Relation, BlockInterface}
