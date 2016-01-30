{Direction, oppositeOf} = require './block-interface'

VerticalDirection =
  above: 'above'
  below: 'below'

{above, below} = VerticalDirection

verticallyOppositeOf = (direction) ->
  switch direction
    when above then below
    when below then above
    else throw new Error("invalid vertical direction: #{direction}")

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
  withCacheFields = (block) ->
    block.$$locatedAt = {}
    block.$$nextInSequenceAt = {}
    block

  $setupCachedBlockAt: (direction) ->
    block = @cursor.at direction
    return block unless block?
    withCacheFields block

    @cursor.$$nextInSequenceAt[direction] = block
    block.$$nextInSequenceAt[oppositeOf direction] = @cursor

    [position, oppositePosition] =
    switch verticalOffset = block.depth() - @cursor.depth()
      when 0 then [direction, oppositeOf direction]
      when -1, 1
        position = if verticalOffset == 1 then below else above
        [position, verticallyOppositeOf position]
      else
        throw new Error("can't yet handle offsets larger 1")

    @cursor.$$locatedAt[position] = block
    block.$$locatedAt[oppositePosition] = @cursor

    block

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
    return next if next = @cursor.$$nextInSequenceAt[direction]
    @$setupCachedBlockAt direction

module.exports = {BlockCache, VerticalDirection, verticallyOppositeOf}
