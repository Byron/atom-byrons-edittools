BlockCache = require '../../lib/block-cache'
ExampleBlock = require '../utils/example-block'
{Direction} = require '../../lib/block-interface'

describe "BlockCache", ->
  v = null
  sequence =
    function:
      fn: v
      name: v
      arguments:
        1:
          'mut x': v
          '&y': v
        2:
          u32: v
          usize: v
      return:
        u8: v
      body:
        '42': v

  sequence = ExampleBlock.makeSequenceDF sequence
  {left, right} = Direction

  block = (index) -> new ExampleBlock sequence, index
  blockCache = (index) -> new BlockCache block index

  it 'should treat the first block as child of its (virtual) root', ->
    expect(blockCache(1).$root.$$children.length).toBe 1

  for key, direction of Direction
    ((direction) ->
      describe "cursor", ->
        beforeEach ->
          console.log 'before', direction
          @cd = switch direction
            when left then blockCache(0)
            when right then blockCache(sequence.length - 1)
            else throw new Error("unknown direction: #{direction}")

        describe "advance() to #{direction}", ->
          it "advance and returns the cursor", ->
            console.log 'advance 1'
            c = blockCache 1
            last_cursor = c.cursor
            expect(c.advance direction).toBe c.cursor
            expect(c.cursor).not.toBe last_cursor

          it "returns null if it reaches end of document and doesn't advance cursor", ->
            console.log 'advance 2'
            last_cursor = @cd.cursor
            expect(@cd.advance direction).toBe null
            expect(@cd.cursor).toBe last_cursor

        describe "peek() to #{direction}", ->
          it "should not advance cursor when peeking", ->
            c = blockCache 1
            last_cursor = c.cursor
            expect(c.peek direction).toBeTruthy()
            expect(c.cursor).toBe last_cursor

          it "should return the same result if peeking multiple times", ->

          it "does not overwrite "
    )(direction)
