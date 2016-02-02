{TraversalDirection} = require './block-interface'

Relationship =
  parent: 'parent'
  child: 'child'
  nextSibling: 'nextSibling'
  previousSibling: 'previousSibling'

{parent, child, nextSibling, previousSibling} = Relationship
{previous, next} = TraversalDirection

oppositeOf =
  parent: child
  child: parent
  nextSibling: previousSibling
  previousSibling: nextSibling
  next: TraversalDirection.previous
  previous: TraversalDirection.next

toRelation =
  next: nextSibling
  previous: previousSibling

publicOppositeOf = (directionOrRelation) ->
  oppositeOf[directionOrRelation] or
  ((d) ->
    throw new Error("invalid direction or relation: #{d}"))(directionOrRelation)

publicDirectionToRelation = (direction) ->
  toRelation[direction] or
  ((d) -> throw new Error("invalid direction: #{d}"))(direction)

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
# It's worth noting that the root of the tree will change as the traversal
# proceeds, as we don't expect it to begin top-most. After all, we discover the
# document as we traverse it.
#
# The cache behaves much like a lexer, such that it has a cursor pointing to a
# current block, and allows to peek in a direction without adjusting the cursor.
class BlockCache
  stopWalk = true
  walk = (block, next, visitor) ->
    stop = visitor block while not stop && block = next(block)
    block

  peekFrom = (fromBlock, direction) ->
    return next if next = fromBlock.$$cached[direction]
    setupNextCachedBlockAt fromBlock, direction

  withCacheFields = (block) ->
    block.$$cached = {}
    block

  findBlockOriginAndPickupSibling = (fromBlock, direction, nextBlockDepth) ->
    siblingParentDepth = nextBlockDepth - 1
    relation = child
    sibling = null
    toPrevious = previous

    towardsPreviousBlocks = (b) -> peekFrom b, toPrevious
    andDoParentSearch = if direction != toPrevious
      andFindViableParentKeepingSibling = (b) ->
        depth = b.depth()
        sibling = b if !sibling && depth == nextBlockDepth
        depth == siblingParentDepth
    else
      andFindViableParent = (b) -> b.depth() == siblingParentDepth

    origin = walk fromBlock, towardsPreviousBlocks, andDoParentSearch
    {origin, sibling, relation}

  setupNextCachedBlockAt = (fromBlock, direction) ->
    nextBlock = fromBlock.at direction
    return nextBlock unless nextBlock?
    withCacheFields nextBlock

    fromBlock.$$cached[direction] = nextBlock
    nextBlock.$$cached[oppositeOf[direction]] = fromBlock

    oppositeDirection = oppositeOf[direction]
    sibling = null
    origin = fromBlock
    relation = null
    verticalOffset = nextBlock.depth() - fromBlock.depth()
    switch
      when verticalOffset == 0
        relation = direction
        sibling = fromBlock
      when Math.abs(verticalOffset) == 1
        relation = if verticalOffset > 0 then child else parent
      else
        {origin, sibling, relation} =
        findBlockOriginAndPickupSibling fromBlock, direction, nextBlock.depth()

    unless relation?
      throw new Error "forgot to define relation between blocks"
    unless origin?
      throw new Error "did not find viable origin block - traversed AST
                       is inconsistent"

    if verticalOffset != 0 and not sibling?
      siblingDepth = nextBlock.depth()
      inOppositeDirection =
        (b) -> b.$$cached[oppositeDirection]
      andTakeFirstSibling = (b) -> b.depth() == siblingDepth
      sibling = walk nextBlock, inOppositeDirection, andTakeFirstSibling

    if sibling? and not nextBlock.$$cached[toRelation[oppositeDirection]]?
      unless sibling.depth() == nextBlock.depth()
        throw new Error 'invalid siblings detected'
      nextBlock.$$cached[toRelation[oppositeDirection]] = sibling
      sibling.$$cached[toRelation[direction]] = nextBlock

    nextBlock.$$cached[oppositeOf[relation]] = origin
    origin.$$cached[relation] = nextBlock

  $setupCachedBlockAt: (direction) ->
    setupNextCachedBlockAt @cursor, direction

  constructor: (firstBlock) ->
    @cursor = withCacheFields firstBlock

  # Advance the cache's cursor to the given block direction and returns changed
  # cursor or null if the document ended. In the latter case, the cursor did not
  # change
  advance: (direction) ->
    if next = @peek direction
      return @cursor = next
    null

  # Peek towards the given direction, without advancing it
  peek: (direction) ->
    unless direction of TraversalDirection
      throw new Error "invalid direction: #{direction}"
    peekFrom @cursor, direction

module.exports = {BlockCache, Relationship}
module.exports.oppositeOf = publicOppositeOf
module.exports.directionToRelation = publicDirectionToRelation
