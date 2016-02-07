
ExpansionDirection =
  inward: 'inward'
  outward: 'outward'

BoundLocation =
  top: 'top'
  bottom: 'bottom'

# Implements an algorithm to grow and shrink a selection along an abstract
# syntax tree.
class Expander
  constructor: (@cache) ->
    @top = @bottom = @origin = @cache.cursor

  # Expand the block bounds to the given direction to grow it or shrink it.
  # Returns an object with bound blocks for each direction.
  # It's possible for the bounds to not change between calls if there is no
  # space to grow.
  # It returns null if there is no space to shrink as we are already pointing
  # to a single block with both bounds
  expand: (direction) ->

    {@top, @bottom}


module.exports = {Expander, ExpansionDirection, BoundLocation}
