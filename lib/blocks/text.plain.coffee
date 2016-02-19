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
  constructor: (@$cp, @$cd=null, @$cr=null) ->
  at: (direction, editor) ->
    tbd()

  trimmedLine = (editor, row) ->
    editor.lineTextForBufferRow(row).trim()

  isPositionedWithinWhitespace = (p, editor) ->
    line = editor.lineTextForBufferRow p.row
    return true if line.length == 0
    matches = /^\s+/.exec line
    return false unless matches
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

  @toSequentialRange = (start, end) ->
    if end.row < start.row || end.column < start.column
      [end, start]
    else
      [start, end]

  range: (editor) ->
    return @$cr if @$cr?
    handler = (info) =>
      console.log info
      @$cr = info.range if info.range.containsPoint @$cp
      info.stop()

    for [scanMethod, endPosition] in [
      [editor.scanInBufferRange, editor.getBuffer().getEndPosition()],
      [editor.backwardsScanInBufferRange, editor.getBuffer().getFirstPosition()]
    ]
      scanMethod.bind(editor)(editor.getLastCursor().wordRegExp(),
                              [@$cp, endPosition],
                              handler)
      break if @$cr?
    throw new Error "can only find words right now" unless @$cr?
    @$cr
module.exports = PlainBlock
