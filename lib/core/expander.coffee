{Relationship} = require './block-cache'

ExpansionDirection =
  inward: 'inward'
  outward: 'outward'

BoundLocation =
  top: 'top'
  bottom: 'bottom'

# Implements an algorithm to grow and shrink a selection along an abstract
# syntax tree.
class Expander
  {inward, outward} = ExpansionDirection
  {nextSibling, previousSibling, parent} = Relationship

  tbd = () -> throw new Error "tbd"

  peekAt = (cache, cursor, relation) ->
    cache.cursor = cursor
    cache.peek relation

  constructor: (@cache) ->
    @$top = @$bottom = @cache.cursor
    @history = [@cursor()]
    @hid = 1

  # Expand the block bounds to the given direction to grow it or shrink it.
  # Returns an object with bound blocks for each direction.
  # It's possible for the bounds to not change between calls if there is no
  # space to grow.
  # It returns null if there is no space to shrink as we are already pointing
  # to a single block with both bounds.
  # *Note*: To assure inward expansion will end up at the same starting point,
  # we will cache all expansion results so far.
  expand: (direction) ->
    switch direction
      when outward
        return @history[@hid++] if @hid < @history.length

        newTop = peekAt @cache, @$top, previousSibling
        newBottom = peekAt @cache, @$bottom, nextSibling

        @$top = newTop if newTop?
        @$bottom = newBottom if newBottom?

        if @$top != newTop and @$bottom != newBottom and
          (parentBlock = peekAt @cache, @$top, parent)?
            @$top = @$bottom = parentBlock

        return @history[@hid++] = @cursor()
      when inward
        return if @hid > 1
          @history[--@hid-1]
        else
          null

    throw new Error "shouldnt ever get here"

  # Returns the current bound with blocks for each direction. Result is
  # similar to what you can expect from `expand()`
  cursor: () -> {top: @$top, bottom: @$bottom}


module.exports = {Expander, ExpansionDirection, BoundLocation}
