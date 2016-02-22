path = require 'path'
fs = require 'fs'

PlainBlock = require '../../../lib/blocks/text.plain'
{Point, Range} = require 'atom'
initTextBlockMatchers = require './text.plain-matchers'

describe "text.plain", ->
  need = it
  pending = xit

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

  it "can be constructed from buffer position", ->
    b = PlainBlock.newFromBufferPosition(@editor.getCursors()[0]
      .getBufferPosition())
    expect(b).toBeDefined()

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
      
