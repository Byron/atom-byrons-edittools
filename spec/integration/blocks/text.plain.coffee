path = require 'path'
fs = require 'fs'
_ = require 'lodash'

PlainBlock = require '../../../lib/blocks/text.plain'
{TraversalDirection} = require '../../../lib/core/block-interface'
{Point, Range} = require 'atom'
initTextBlockMatchers = require './text.plain-matchers'

{next, previous} = TraversalDirection

describe "text.plain", ->
  need = it
  pending = xit
  
  checkThrowIfUnknownDepthOnCall = (m) ->
    b = block 2, 11
    b.$cd = 42
    expect(() -> b[m]()).toThrow new Error "unknown depth: 42"

  beforeEach ->
    initTextBlockMatchers(this)
    waitsForPromise -> atom.workspace.open('sample.txt')
    runs ->
      data = fs.readFileSync path.join __dirname, '..', '..', 'fixtures',
        'buffers', 'text.plain'
      @editor = atom.workspace.getActiveTextEditor()
      @editor.setText data.toString()
      @editor.setCursorBufferPosition([0, 0])

  block = (row, column) -> new PlainBlock(new Point(row, column))
  
  describe "initial cursor position", ->
    for [description, position, rangeOrWord, depth] in [
      ["selects whitespace", [8, 6], [[8, 5], [8, 8]], 3]
      ["selects words", [5, 2], "new", 3]
      ["selects the line if it is completley empty", [6, 0], "", 2]
      ["selects word at end of line", [2, 13], "world", 3]
      ["selects whitespace at end of line", [3, 15], [[3, 14], [3, 16]], 3]
    ]
      ((position, rangeOrWord, depth) ->
        it description, ->
          b = block.apply(null, position)
          expect(b.depth @editor).toBe depth
          if _.isString rangeOrWord
            word = rangeOrWord
            expect(b).toSelect word, @editor
          else
            desiredRange = Range.fromObject(rangeOrWord)
            expect(b.range @editor).toEqual desiredRange
      )(position, rangeOrWord, depth)
        
  it "can be constructed from buffer position", ->
    b = PlainBlock.newFromBufferPosition(@editor.getCursors()[0]
      .getBufferPosition())
    expect(b).toBeDefined()
    
  describe "at()", ->
    it "should throw at an unknown depth", ->
      checkThrowIfUnknownDepthOnCall 'at', @editor
      
    it "should throw on unknown direction", ->
      b = block 2, 1
      error = new Error "unknown direction: location"
      expect(() => b.at 'location', @editor).toThrow error
      
    it "should not traverse next at end of line", ->
      b = block 2, 11
      expect(b.at next, @editor).toBe null
      
    it "should not traverse next at end of line, skipping WS", ->
      b = block 3, 13
      expect(b.at next, @editor).toBe null
    
    for [direction, word] in [
      [previous, 'other'],
      [next, 'paragraph']
    ]
      ((direction, word) ->
        it "should produce #{direction} block from whitespace (WS)", ->
          b = block 8, 6
          expect(b.at(direction, @editor)).toSelect word, @editor
      )(direction, word)
      
    for [direction, start, end] in [
      [previous, [10, 0], [10, 3]],
      [next, [10, 12], [10,16]]
    ]
      ((direction, start, end) ->
        it "should produce #{direction} word block from word, skipping WS", ->
          b = block 10, 7
          desiredRange = new Range start, end
          expect(b.at(direction, @editor).range @editor).toEqual desiredRange
      )(direction, start, end)
      
    for [position, start, end] in [
      [[3, 3], [3, 0], [3, 16]]
      [[5, 1], [5, 0], [5, 13]]
    ]
      ((position, start, end) ->
        it "should move from word to line level at line start, skipping WS", ->
          b = block.apply(null, position)
          expect(b.depth @editor).toBe 3
          nb = b.at previous, @editor
          
          expect(nb.depth @editor).toBe 2
          entireLine = new Range start, end
          expect(nb.range @editor).toEqual entireLine
      )(position, start, end)
    
  describe "depth()", ->
    it "caches the depth", ->
      b = block 0, 0
      expect(b.depth @editor).toBe b.depth @editor

    describe "words (W) at depth 3", ->
      for [row, column, description] in [
        [3, 2, "W at beginning of word"]
        [3, 3, "W in middle of word"]
        [3, 14, "W at end of word"]
        [5, 0, "W at start of line and word"]
        [5, 13, "W at end of line and word"]
        [8, 6, "W between words"]
        [3, 0, "W in whitespace at start of line"]
      ]
        ((row, column) ->
          need description, ->
            b = block row, column
            expect(b.depth(@editor)).toBe 3
            expect(b.$cd).toBe 3
        )(row, column)
      null

  describe "range(..)", ->
    it "caches the range", ->
      b = block 3, 0
      expect(b.range(@editor)).toBe b.range @editor
      
    it "should throw if depth is invalid", ->
      checkThrowIfUnknownDepthOnCall 'range'

    describe "for words (W)", ->
      for [row, column, description, word] in [
        [2, 2, "range at beginning of W",                     "hello"]
        [2, 7, "range at nd of W",                            "hello"]
        [3, 5, "range in middle of W",                        "another"]
        [8, 15, "range at the end of document",               "paragraph"]
        [8, 6, "range even if W is whitespace between words", "   "]
        [3, 15, "range if W is whitespace at end of line",    "  "]
        [3, 0, "range if W is whitespace at start of line",   "  "]
      ]
        ((row, column, word) ->
          it "#{description} word: '#{word}' row: #{row}, col: #{column}", ->
            b = block row, column
            expect(b).toSelect(word, @editor)
        )(row, column, word)

    describe "for lines (L)", ->
      enforceDepthToLine = (b) -> b.$cd = 2; b
      it "selects the entire line, with whitespace untrimmed", ->
        b = enforceDepthToLine block 3, 1
        expect(b).toSelect("  another line  ", @editor)

      it "selects the entire line at the start of the document", ->
        b = enforceDepthToLine block 8, 1
        expect(b).toSelect("other   paragraph", @editor)
        
    describe "for paragraphs (P)", ->
      enforceDepthToParagraph = (b) -> b.$cd = 1; b
      
      for [description, position, range] in [
        ["should select entire paragraphs, spanning multiple lines",
         [2, 1],
         new Range [2, 0], [3, 16]],
        ["should select single-line paragraphs",
         [5, 5],
         new Range [5, 0], [5, 13]],
        ["should select single-line paragraphs at end of document",
         [8, 3],
         new Range [8, 0], [8, 17]]
      ]
        ((position, range) ->
          it description, ->
            b = enforceDepthToParagraph block.apply(null, position)
            expect(b.range(@editor)).toEqual range
        )(position, range)
      
