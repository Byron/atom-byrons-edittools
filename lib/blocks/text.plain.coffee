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

  depth: (editor) ->
    return @$cd if @$cd?
    @$cd = 3
           
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
    trimmedLineAt = (row) -> (editor.lineTextForBufferRow(row) or '').trim()
    points = []
    
    for direction in [-1, 1]
      row = cp.row
      while (trimmedLineAt row).length > 0
        row += direction
      row = if row != cp.row then row - direction else cp.row
      points.push new Point row, 0
    
    points[1].column = editor.lineTextForBufferRow(points[1].row).length
    Range.fromObject points

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

