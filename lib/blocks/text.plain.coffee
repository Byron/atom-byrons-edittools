{TraversalDirection, Relation, BlockInterface} =
  require '../../lib/core/block-interface'
{previous, next} = TraversalDirection
{Point, Range} = require 'atom'

# block where traversal order is depth first
class PlainBlock extends BlockInterface
  PARAGRAPH_DEPTH = 1
  LINE_DEPTH = 2
  WORD_DEPTH = 3
  
  @newFromBufferPosition = (position) -> new PlainBlock position
  
  positionForRange = (direction, r) ->
    switch direction
      when next then r.end.translate [0, +1]
      when previous then r.start.translate [0, -1]
      else throw new Error "unknown direction: #{direction}"

  wordAt = (cr, direction, editor) ->
    line = editor.lineTextForBufferRow cr.end.row
    np = positionForRange direction, cr
    nr = wordRange np, editor
    
    trimmedSelectionIsEmpty = () ->
      editor.getTextInBufferRange(nr).trim().length == 0
      
    return null if direction == next and trimmedSelectionIsEmpty()
    
    if cr.start.column == 0 or trimmedSelectionIsEmpty()
      nr = new Range nr.start, new Point nr.start.row, line.length
      new PlainBlock nr.start, LINE_DEPTH, nr
    else
      new PlainBlock np, WORD_DEPTH, nr

  # Construct from the cursor point at which we are located
  # $cp ~= cursorPosition
  # $cd ~= cached depth
  constructor: (@$cp, @$cd=null, @$cr=null) ->
  at: (direction, editor) ->
    handler =
      switch d = @depth editor
        when WORD_DEPTH then wordAt
        else throw new Error "unknown depth: #{d}"
    
    handler @range(editor), direction, editor

  depth: (editor) ->
    return @$cd if @$cd?
    @$cd = WORD_DEPTH
           
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
            if p.row == cp.row then p else positionAtLineEnd()
          else positionAtLineStart()
        
        pp =
          if (p = seen[previous])?
            if p.row == cp.row then p else positionAtLineStart()
          else positionAtLineEnd()
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
      (switch d = @depth(editor)
        when PARAGRAPH_DEPTH then paragraphRange
        when LINE_DEPTH then lineRange
        when WORD_DEPTH then wordRange
        else throw new Error "unknown depth: #{d}"
      )(@$cp, editor)
    @$cr
module.exports = PlainBlock

