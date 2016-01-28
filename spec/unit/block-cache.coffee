BlockCache = require '../../lib/block-cache'
ExampleBlock = require '../utils/example-block'
{Direction} = require '../../lib/block-interface'

fdescribe "BlockCache", ->
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
  block_cache = (index) -> new BlockCache block index

  it 'should treat the first block as child of its (virtual) root', ->
    expect(block_cache(1).$root.$$children.length).toBe 1

  describe 'cursor', ->
    describe 'advance', ->
      beforeEach ->
        @c = block_cache 1

      for _, direction of Direction
        ((direction) ->
          it "advances to the #{direction} and returns the cursor", ->
            last_cursor = @c.cursor
            expect(@c.advance direction).toBe @c.cursor
            expect(@c.cursor).not.toBe last_cursor

          it "returns null if it reaches end of document to #{direction} and doesn't advance cursor", ->
            @c = switch direction
              when left then block_cache(0)
              when right then block_cache(sequence.length - 1)
              else throw new Error("unknown direction: #{direction}")
            last_cursor = @c.cursor
            expect(@c.advance direction).toBe null
            expect(@c.cursor).toBe last_cursor
        )(direction)
