BlockCache = require '../../lib/block-cache'
ExampleBlock = require '../utils/example-block'
{Direction, oppositeOf} = require '../../lib/block-interface'

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

  for key, direction of Direction
    ((direction) ->
      describe "cursor", ->
        beforeEach ->
          @cd = switch direction
            when left then blockCache(0)
            when right then blockCache(sequence.length - 1)
            else throw new Error("unknown direction: #{direction}")

          @c1 = blockCache 1

        describe "advance() to #{direction}", ->
          it "advance and returns the cursor", ->
            lastCursor = @c1.cursor
            expect(@c1.advance direction).toBe @c1.cursor
            expect(@c1.cursor).not.toBe lastCursor

          it "returns null if it reaches end of document and doesn't advance cursor", ->
            lastCursor = @cd.cursor
            expect(@cd.advance direction).toBe null
            expect(@cd.cursor).toBe lastCursor

        describe "peek() to #{direction}", ->
          it "must not change cursor when peeking", ->
            lastCursor = @c1.cursor
            expect(@c1.peek direction).toBeTruthy()
            expect(@c1.cursor).toBe lastCursor

          it "should return the same result if peeking multiple times", ->
            expect(@c1.peek direction).toBe @c1.peek direction

          it "returns null at the end of a document", ->
            expect(@cd.peek direction).toBe null

          # TODO: put back in once it works
          xit "peek results are consistent in the face of advance", ->
            lastCursor = @cd.cursor
            expect(peeked = @cd.peek oppositeOf direction).not.toEqual @cd.peek direction
            expect(nextCursor = @cd.advance oppositeOf direction).toBe peeked
            expect(@cd.peek direction).toBe lastCursor

            expect(@cd.advance direction).toBe lastCursor
            expect(@cd.peek oppositeOf direction).toBe nextCursor
    )(direction)

  describe "caching", ->
    it "should initialize the cache on the cursor", ->
      b = blockCache(1).cursor
      expect(b.$$parent).toBe null
      expect(b.$$firstChild).toBe null
      expect(b.$$nextSibling).toBe null
      expect(b.$$prevSibling).toBe null

    for fnName in ['peek', 'advance']
      ((fnName) ->
        describe "#{fnName}()", ->

          it "#{fnName}(): it should setup siblings", ->
            c =  blockCache(1)
            lc = c.cursor
            b = c[fnName](right)
            expect(lc.$$nextSibling).toBe b
            expect(b.$$prevSibling).toBe lc
            expect(b.$$nextSibling).toBe null
      )(fnName)
