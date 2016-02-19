{TraversalDirection, Relation, BlockInterface} =
  require '../../lib/core/block-interface'
{previous, next} = TraversalDirection
{Point, Range} = require 'atom'


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
    return @$cd if @$cd?
    @$cd = tryObtainParagraphDepth(@$cp, editor) or
            tryObtainLineDepth(@$cp, editor) or
            3
           
  wordRange = (cp, editor) ->
    dirs = []
    seen = {}

    handler = (direction, info) ->
      if info.range.containsPoint cp
        dirs.push info.range
      else
        seen[direction] =
        switch direction
          when next then info.range.start
          when previous then info.range.end

      info.stop()

    for [direction, scanMethod, endPosition] in [
      [next, editor.scanInBufferRange,
                      editor.getBuffer().getEndPosition()],
      [previous, editor.backwardsScanInBufferRange,
                      editor.getBuffer().getFirstPosition()]
    ]
      scanMethod.call(editor, editor.getLastCursor().wordRegExp(),
                              [cp, endPosition],
                              handler.bind(null, direction))

    cr = dirs[0]
    if (nr = dirs[1])?
      cr.start.column = nr.start.column if cr.start.column > nr.start.column
      cr.end.column = nr.end.column if cr.end.column < nr.end.column
    unless cr?
      (useWhitespaceAsRange = () ->
        positionAtLineEnd = () ->
          new Point cp.row, editor.lineTextForBufferRow(cp.row).length
        positionAtLineStart = () ->
          new Point cp.row, 0

        np =
          if (p = seen[next])?
            if p.row == cp.row
              p
            else
              positionAtLineEnd()
        
        unless np?
          np = positionAtLineStart()

        pp =
          if (p = seen[previous])?
            if p.row == cp.row
              p
            else
              positionAtLineStart()

        unless pp?
          pp = positionAtLineEnd()
        
        cr = new Range pp, np
      )()
    cr
    
  lineRange = (cp, editor) ->
    l = editor.lineTextForBufferRow cp.row
    new Range [cp.row, 0], [cp.row, l.length]
    
  paragraphRange = (cp, editor) ->
    tbd()

  range: (editor) ->
    return @$cr if @$cr?

    @$cr =
      (switch @depth(editor)
        when 1 then paragraphRange
        when 2 then lineRange
        when 3 then wordRange
        else throw new Error "unknown depth: #{@depth(editor)}"
      )(@$cp, editor)
    @$cr
module.exports = PlainBlock

