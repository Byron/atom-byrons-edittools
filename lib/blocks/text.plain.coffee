{TraversalDirection, Relation, BlockInterface} =
                                        require '../../lib/core/block-interface'
{previous, next} = TraversalDirection

# block where traversal order is depth first
class PlainBlock extends BlockInterface
  @newFromBufferPosition = (position) -> new PlainBlock position

  # Construct from the cursor point at which we are located
  # $cp ~= cursorPosition
  # $cd ~= cached depth
  constructor: (@$cp, @$cd=null) ->
  at: (direction, editor) ->
    tbd()

  depth: (editor) ->
    return @cd if @$cd?
    tbd()




module.exports = PlainBlock
