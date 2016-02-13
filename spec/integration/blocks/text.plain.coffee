path = require 'path'
fs = require 'fs'

PlainBlock = require '../../../lib/blocks/text.plain'
{Point} = require 'atom'

describe "text.plain", ->
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

  pending "empty lines to be paragraphs at depth 0", ->
    b = block 0, 0
    expect(b.depth(@editor)).toBe 0
    expect(b.$cd).toBe 0

  pending "whitespace to be ignored, and thus be similar to empty lines", ->
