path = require 'path'
fs = require 'fs'

PlainBlock = require '../../../lib/blocks/text.plain'
{Point} = require 'atom'
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
    describe "paragraphs (P) at depth 1", ->
      for column in [0, 1]
        for [row, description] in [
          [0, "empty lines on top of document to be P"],
          [1, "empty lines within the document to be P, ignoring whitespace"],
          [2, "lines with empty line above to be P, ignoring whitespace"]
        ]
          ((row) ->
            need description, ->
              b = block row, column
              expect(b.depth(@editor)).toBe 1
              expect(b.$cd).toBe 1
            )(row)

    describe "lines (L) at depth 2", ->
      need "L within paragraph, ignoring whitespace", ->
        for column in [0, 1]
          b = block 3, column
          expect(b.depth(@editor)).toBe 2
          expect(b.$cd).toBe 2

    describe "words (W) at depth 3", ->
      for [row, column, description] in [
        [3, 2, "W at beginning of word"]
        [3, 3, "W in middle of word"]
        [3, 14, "W at end of word"]
        [5, 0, "W at start of line and word"]
        [5, 13, "W at end of line and word"]
      ]
        ((row, column) ->
          need description, ->
            b = block row, column
            expect(b.depth(@editor)).toBe 3
            expect(b.$cd).toBe 3
        )(row, column)
      null

      it "should return depth 3 between words", ->
        b = block 8, 6
        expect(b.depth(@editor)).toBe 3

  describe "range(..)", ->
    describe "for words (W)", ->
      for [description, word, row, column] in [
        ["range at beginning of W", "hello", 2, 2]
        ["range at end of W", "hello", 2, 7]
        ["range in middle of W", "another", 3, 5]
        ["range of W at the end of document", "paragraph", 8, 15]
      ]
        ((row, column, word) ->
          it "#{description} word: '#{word}' row: #{row}, col: #{column}", ->
            b = block row, column
            expect(b).toSelect(word, @editor)
        )(row, column, word)

      it "should return a range at cursor if there is no word", ->
        b = block 8, 6
        expect(b).toSelect('', @editor)
        r = b.range(@editor)

        expect(r.start).toEqual b.$cp
        expect(r.start).not.toBe b.$cp
        expect(r.end).toEqual b.$cp
        expect(r.end).not.toBe b.$cp
