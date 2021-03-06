{TraversalDirection} = require './block-interface'

Relationship =
  parent: 'parent'
  child: 'child'
  nextSibling: 'nextSibling'
  previousSibling: 'previousSibling'

{parent, child, nextSibling, previousSibling} = Relationship
{previous, next} = TraversalDirection

knownDirectionsAndRelations = oppositeOf =
  parent: child
  child: parent
  nextSibling: previousSibling
  previousSibling: nextSibling
  next: TraversalDirection.previous
  previous: TraversalDirection.next

toRelation =
  next: nextSibling
  previous: previousSibling

toDirection =
  nextSibling: next
  previousSibling: previous
  parent: previous
  child: next

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
  neverStop = false
  walk = (block, next, visitor) ->
    stop = visitor block while not stop && block = next(block)
    block

  peekFrom = (fromBlock, directionOrRelation, editor) ->
    return next if next = fromBlock.$cached[directionOrRelation]
    setupNextCachedBlockAt fromBlock, directionOrRelation, editor

  withCacheFields = (block) ->
    block.$cached = {}
      # Returns the cached block at the given direction or relation.
      # use `peek()` if you want to try filling the cache beforehand.
      # May be undefined if there is no cache yet.
    block.cached = (directionOrRelation) ->
      @$cached[directionOrRelation]

    block

  findBlockOriginAndPickupSibling =
    (fromBlock, direction, nextBlockDepth, editor) ->
      siblingParentDepth = nextBlockDepth - 1
      relation = child
      sibling = null
      toPrevious = previous

      towardsPreviousBlocks = (b) -> peekFrom b, toPrevious, editor
      andDoParentSearch = if direction != toPrevious
        andFindViableParentKeepingSibling = (b) ->
          depth = b.depth(editor)
          sibling = b if !sibling && depth == nextBlockDepth
          depth == siblingParentDepth
      else
        andFindViableParent = (b) -> b.depth(editor) == siblingParentDepth

      origin = walk fromBlock, towardsPreviousBlocks, andDoParentSearch
      {origin, sibling, relation}

  setupNextCachedBlockAt = (fromBlock, directionOrRelation, editor) ->
    (if directionOrRelation of TraversalDirection
      setupNextCachedBlockAtDirection
    else if directionOrRelation of Relationship
      setupNextCachedBlockAtRelation
    else
      -> throw new Error "unknown case encountered
                          - fix me: #{directionOrRelation}"
    )(fromBlock, directionOrRelation, editor)

  setupNextCachedBlockAtRelation = (fromBlock, relation, editor) ->
    direction = toDirection[relation]
    blockDepth = fromBlock.depth(editor)
    andPeek = (b) -> peekFrom b, direction, editor
    {isGoodCandidate, butAbortIfNeeded} = switch relation
      when nextSibling, previousSibling
        isGoodCandidate: (nb) -> nb.depth(editor) == blockDepth
        butAbortIfNeeded: (c) -> c.depth(editor) <= blockDepth
      when parent
        isParent = (b) -> b.depth(editor) == blockDepth - 1
        isGoodCandidate: isParent
        butAbortIfNeeded: isParent
      when child
        isChild = (b) -> b.depth(editor) == blockDepth + 1
        isGoodCandidate: isChild
        butAbortIfNeeded: isChild
      else throw new Error "unexpected relation: #{relation}"

    candidate = walk fromBlock, andPeek, butAbortIfNeeded
    if candidate? and isGoodCandidate(candidate)
      candidate
    else null

  setupNextCachedBlockAtDirection = (fromBlock, direction, editor) ->
    nextBlock = fromBlock.at direction, editor
    return nextBlock unless nextBlock?
    withCacheFields nextBlock

    fromBlock.$cached[direction] = nextBlock
    nextBlock.$cached[oppositeOf[direction]] = fromBlock

    oppositeDirection = oppositeOf[direction]
    sibling = null
    origin = fromBlock
    relation = null
    verticalOffset = nextBlock.depth(editor) - fromBlock.depth(editor)
    switch
      when verticalOffset == 0
        relation = direction
        sibling = fromBlock
      when Math.abs(verticalOffset) == 1
        relation = if verticalOffset > 0 then child else parent
      else
        {origin, sibling, relation} =
        findBlockOriginAndPickupSibling fromBlock, direction,
                                        nextBlock.depth(editor),
                                        editor

    unless relation?
      throw new Error "forgot to define relation between blocks"
    unless origin?
      throw new Error "did not find viable origin block towards '#{direction}' -
                       traversed AST is inconsistent"

    if verticalOffset != 0 and not sibling?
      siblingDepth = nextBlock.depth(editor)
      inOppositeDirection =
        (b) -> b.$cached[oppositeDirection]
      andTakeFirstSibling = (b) -> b.depth(editor) == siblingDepth
      sibling = walk nextBlock, inOppositeDirection, andTakeFirstSibling

    if sibling? and not nextBlock.$cached[toRelation[oppositeDirection]]?
      unless sibling.depth(editor) == nextBlock.depth(editor)
        throw new Error 'invalid siblings detected'
      nextBlock.$cached[toRelation[oppositeDirection]] = sibling
      sibling.$cached[toRelation[direction]] = nextBlock

    nextBlock.$cached[oppositeOf[relation]] = origin
    origin.$cached[relation] = nextBlock

  constructor: (firstBlock, @editor) ->
    @$cursor = withCacheFields firstBlock
    throw new Error "need editor to be set" unless editor?

  # Returns our cursor
  cursor: () -> @$cursor

  # Sets the cursor the given block. If it is not yet owned by a cache,
  # we will add our data structures to it.
  # Returns this instance
  setCursor: (cursor) ->
    unless cursor.$cached?
      withCacheFields cursor
    @$cursor = cursor
    this

  # Advance the cache's cursor to the given block direction or relation and
  # returns changed cursor or null if the document ended. In the latter case,
  # the cursor did not change
  advance: (directionOrRelation) ->
    if next = @peek directionOrRelation
      return @$cursor = next
    null

  # Peek towards the given direction or relation, without advancing it
  peek: (directionOrRelation) ->
    unless directionOrRelation of knownDirectionsAndRelations
      throw new Error "invalid direction: #{directionOrRelation}"
    peekFrom @$cursor, directionOrRelation, @editor

module.exports = {BlockCache, Relationship}
module.exports.oppositeOf = publicOppositeOf
module.exports.directionToRelation = publicDirectionToRelation
