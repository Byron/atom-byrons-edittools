{BlockCache, VerticalDirection, verticallyOppositeOf} = require '../../lib/block-cache'
ExampleBlock = require '../utils/example-block'
{Direction, oppositeOf} = require '../../lib/block-interface'

describe "BlockCache", ->
  v = null
  sequence =
    function:
      _fn: v
      _name: v
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
  {above, below} = VerticalDirection

  block = (index) -> new ExampleBlock sequence, index
  blockCache = (index) -> new BlockCache block index

  it "should properly implement verticallyOppositeOf()", ->
    expect(verticallyOppositeOf above).toBe below
    expect(verticallyOppositeOf below).toBe above

  for key, direction of Direction
    ((direction) ->
      describe "cursor", ->
        beforeEach ->
          @cd = switch direction
            when left then blockCache(0)
            when right then blockCache(sequence.length - 1)
            else throw new Error("unknown direction: #{direction}")

          @c1 = blockCache 1

        it "should initialize the cache on the cursor", ->
          b = @c1.cursor
          expect(b.$$siblingAt).toEqual {}
          expect(b.$$hierarchicallyAt).toEqual {}
          expect(b.$$nextInSequenceAt).toEqual {}

        describe "advance() to #{direction}", ->
          it "advance and returns the cursor", ->
            lastCursor = @c1.cursor
            expect(@c1.advance direction).toBe @c1.cursor
            expect(@c1.cursor).not.toBe lastCursor

          it "returns null if it reaches end of document and doesn't advance cursor", ->
            lastCursor = @cd.cursor
            expect(@cd.advance direction).toBe null
            expect(@cd.cursor).toBe lastCursor

          it "returns siblings, parents and children from cache", ->
            for rootIndex in [1,2]
              c = blockCache rootIndex
              lc = c.cursor
              c.advance direction
              expect(c.advance oppositeOf direction).toBe lc

        describe "peek() to #{direction}", ->
          it "must not change cursor when peeking", ->
            lastCursor = @c1.cursor
            expect(@c1.peek direction).toBeTruthy()
            expect(@c1.cursor).toBe lastCursor

          it "should return the same result if peeking multiple times", ->
            expect(@c1.peek direction).toBe @c1.peek direction

          it "returns null at the end of a document", ->
            expect(@cd.peek direction).toBe null

          it "peek results are consistent in the face of advance", ->
            lastCursor = @cd.cursor
            expect(peeked = @cd.peek oppositeOf direction).not.toEqual @cd.peek direction
            expect(nextCursor = @cd.advance oppositeOf direction).toBe peeked
            expect(@cd.peek direction).toBe lastCursor

            expect(@cd.advance direction).toBe lastCursor
            expect(@cd.peek oppositeOf direction).toBe nextCursor
    )(direction)

  describe "caching", ->
    for fnName in ['peek', 'advance']
      for direction of Direction
        ((fnName, direction) ->
          describe "#{fnName}() to #{direction}", ->
            it "should setup siblings", ->
              c = blockCache 3
              lc = c.cursor
              b = c[fnName](direction)
              expect(lc.depth()).toBe b.depth()

              expect(lc.$$siblingAt[direction]).toBe b
              expect(b.$$siblingAt[oppositeOf direction]).toBe lc
              expect(b.$$siblingAt[direction]).toBeFalsy()

            it "should setup direct parent/child relationships", ->
              c = blockCache 5
              lc = c.cursor
              b = c[fnName](direction)
              expect(Math.abs(lc.depth() - b.depth())).toBe 1

              position = switch direction
                when right then below
                when left then above
                else throw new Error("invalid direction: #{direction}")
              expect(lc.$$hierarchicallyAt[position]).toBe b
              expect(b.$$hierarchicallyAt[verticallyOppositeOf position]).toBe lc
              expect(b.$$hierarchicallyAt[position]).toBeFalsy()
        )(fnName, direction)
