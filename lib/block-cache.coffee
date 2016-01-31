{Direction} = require './block-interface'

VerticalDirection =
  above: 'above'
  below: 'below'

{above, below} = VerticalDirection

verticallyOppositeOf = (direction) ->
  switch direction
    when above then below
    when below then above
    else throw new Error("invalid vertical direction: #{direction}")

oppositeOf =
  above: below
  below: above
  right: Direction.left
  left: Direction.right

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
  stopWalk = true
  walk = (block, next, visitor) ->
    stop = visitor block while not stop && block = next(block)
    block

  peekFrom = (fromBlock, direction) ->
    return next if next = fromBlock.$$nextInSequenceAt[direction]
    setupNextCachedBlockAt fromBlock, direction

  withCacheFields = (block) ->
    block.$$locatedAt = {}
    block.$$nextInSequenceAt = {}
    block

  setupNextCachedBlockAt = (fromBlock, direction) ->
    block = fromBlock.at direction
    return block unless block?
    withCacheFields block

    fromBlock.$$nextInSequenceAt[direction] = block
    block.$$nextInSequenceAt[oppositeOf[direction]] = fromBlock

    origin = fromBlock

    verticalOffset = block.depth() - fromBlock.depth()
    switch
      when verticalOffset == 0
        position = direction
      when Math.abs(verticalOffset) == 1
        position = if verticalOffset > 0 then below else above
      when verticalOffset < -1
        siblingDepth = block.depth()
        targetDepth = siblingDepth - 1
        sibling = null
        inOppositeDirection = (b) -> peekFrom b, oppositeOf[direction]
        andFindViableParentKeepingSibling = (b) ->
          depth = b.depth()
          # TODO: figure out if algorithms should be required to step sizes of 1
          # Maybe a configurable feature. Also: is it needed ?
          # return stopWalk unless Math.abs(depth - siblingDepth) < 2
          sibling = b if !sibling && depth == siblingDepth
          depth == targetDepth
        origin = walk fromBlock, inOppositeDirection, andFindViableParentKeepingSibling
        position = below
        if sibling?
          block.$$locatedAt[oppositeOf[direction]] = sibling
          sibling.$$locatedAt[direction] = block
      else
        throw new Error "can't yet handle offset: #{verticalOffset}"

    throw new Error "did not find viable origin block - traversed AST is inconsistent" unless origin?
    block.$$locatedAt[oppositeOf[position]] = origin
    origin.$$locatedAt[position] = block

  $setupCachedBlockAt: (direction) ->
    setupNextCachedBlockAt @cursor, direction

  constructor: (firstBlock) ->
    @cursor = withCacheFields firstBlock

  # Advance the cache's cursor to the given block direction and returns changed cursor
  # or null if the document ended. In the latter case, the cursor did not change
  advance: (direction) ->
    if next = @peek direction
      return @cursor = next
    null

  # Peek towards the given direction, without advancing it
  peek: (direction) ->
    peekFrom @cursor, direction

module.exports = {BlockCache, VerticalDirection, verticallyOppositeOf}
