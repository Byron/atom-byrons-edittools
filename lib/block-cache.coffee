{Direction, oppositeOf} = require './block-interface'

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
#
# The cache behaves much like a lexer, such that it has a cursor pointing to a
# current block, and allows to peek in a direction without adjusting the cursor.
class BlockCache
  constructor: (firstBlock) ->
    @cursor = firstBlock
    @peekAt = {}
    @$root = $$parent: null, $$children: [firstBlock]

  # Advance the cache's cursor to the given block direction and returns changed cursor
  # or null if the document ended. In the latter case, the cursor did not change
  advance: (direction) ->
    finalized = (next) =>
      @peekAt = {}
      return @cursor = next

    return finalized next if next = @peekAt[direction]
    return finalized next if next = @cursor.at direction
    null

  # Peek towards the given direction, without advancing it
  peek: (direction) ->
    next = @peekAt[direction]
    return next if next
    @peekAt[direction] = @cursor.at direction


module.exports = BlockCache
