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

  isPositionedWithinWhitespace = (p, editor) ->
    line = editor.lineTextForBufferRow p.row
    matches = /^\s+/.exec line
    return null unless matches
    p.column < matches[0].length

  tryObtainParagraphDepth = (p, editor) ->
    prevRow = p.row - 1
    if (p.column == 0 and prevRow < 0) or
       (isPositionedWithinWhitespace(p, editor) and
        (trimmedLine(editor, p.row).length == 0 or
         trimmedLine(editor, prevRow).length == 0))
      return 1
    null

  tryObtainLineDepth = (p, editor) ->
    if isPositionedWithinWhitespace p, editor
      return 2
    null

  depth: (editor) ->
    return @cd if @$cd?
    @$cd = tryObtainParagraphDepth(@$cp, editor) or
           tryObtainLineDepth(@$cp, editor) or
           3

module.exports = PlainBlock
