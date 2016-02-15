{TraversalDirection, Relation, BlockInterface} =
  require '../../lib/core/block-interface'
{previous, next} = TraversalDirection
{Point} = require 'atom'


# block where traversal order is depth first
class PlainBlock extends BlockInterface
  @newFromBufferPosition = (position) -> new PlainBlock position

  # Construct from the cursor point at which we are located
  # $cp ~= cursorPosition
  # $cd ~= cached depth
  constructor: (@$cp, @$cd=null) ->
  at: (direction, editor) ->
    tbd()

  trimmedLine = (editor, row) ->
    editor.lineTextForBufferRow(row).trim()

  obtainParagraphOrLineDepth = (p, editor) ->
    prevRow = p.row - 1
    if (p.column == 0 and prevRow < 0) or
       trimmedLine(editor, p.row).length == 0 or
       trimmedLine(editor, prevRow).length == 0
      return 0

    tbd()

  depth: (editor) ->
    return @cd if @$cd?
    @$cd = obtainParagraphOrLineDepth @$cp, editor
    unless @$cd?
      tbd()
    @$cd




module.exports = PlainBlock
