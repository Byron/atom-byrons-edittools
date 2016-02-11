path = require 'path'
fs = require 'fs'

require '../../../lib/blocks/text.plain'

describe "text.plain", ->
  beforeEach ->
    waitsForPromise -> atom.workspace.open('sample.txt')
    runs ->
      data = fs.readFileSync path.join __dirname, '..', '..', 'fixtures',
                                       'buffers', 'text.plain'
      @editor = atom.workspace.getActiveTextEditor()
      @editor.setText data.toString()

  it "intermediate: see if we can bring up an editor with text", ->
    expect(@editor.getText().length).not.toBe 0
