path = require 'path'
fs = require 'fs'

PlainBlock = require '../../../lib/blocks/text.plain'
{Point} = require 'atom'

fdescribe "text.plain", ->
  need = it
  pending = xit

  beforeEach ->
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

  describe "paragraphs (P) at depth 0", ->
    for column in [0, 3, 9]
      for [row, description] in [
        [0, "empty lines on top of document to be P"],
        [1, "empty lines within the document to be P, ignoring whitespace"],
        [2, "lines with empty line above to be P, ignoring whitespace"]
      ]
        ((row) ->
          need description, ->
            b = block row, column
            expect(b.depth(@editor)).toBe 0
            expect(b.$cd).toBe 0
          )(row)

  describe "lines (P) at depth 1", ->
    pending "line within paragraph, ignoring whitespace", ->
