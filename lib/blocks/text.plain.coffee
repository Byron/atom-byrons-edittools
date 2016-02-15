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
    throw new Error 'only for points at column 0' unless p.column == 0
    if (prevRow = p.row - 1) < 0 or
       trimmedLine(editor, p.row).length == 0 or
       trimmedLine(editor, prevRow).length == 0
      return 0

    tbd()

  depth: (editor) ->
    return @cd if @$cd?
    if @$cp.column == 0
      @$cd = obtainParagraphOrLineDepth @$cp, editor
    else
      tbd()
    # surrounding = editor.getTextInBufferRange(@cp)
    # return 1 if @cp.column == 0




module.exports = PlainBlock
