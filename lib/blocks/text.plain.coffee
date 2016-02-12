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
    # surrounding = editor.getTextInBufferRange(@cp)
    # return 1 if @cp.column == 0




module.exports = PlainBlock
