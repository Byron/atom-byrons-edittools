{BlockCache, VerticalDirection, verticallyOppositeOf} = require '../../lib/block-cache'
ExampleBlock = require '../utils/example-block'
{TraversalDirection, oppositeOf} = require '../../lib/block-interface'
_ = require 'lodash'

describe "BlockCache", ->
  v = null
  sequence =
    function:
      _0fn: v
      _1name: v
      _2arguments:
        1:
          'mut x': v
        2:
          u32: v
          usize: v
      _return:
        u8: v
      body:
        '42': v

  sequence = ExampleBlock.makeSequenceDF sequence

  {previous, next} = TraversalDirection
  {above, below} = VerticalDirection

  blockCache = (index) -> new BlockCache(new ExampleBlock(sequence, index))
  blockCacheAt = (first) ->
    args = if _.isString(first) then (a for a in arguments) else first
    index = _.findIndex sequence, (p) -> _.isEqual(p, args)
    throw Error "invalid block path: #{(a for a in args).join('.')}" if index < 0
    blockCache index

  if (want = "function|_0fn|_1name|_2arguments|1|mut x|2|u32|usize|_return|u8|body|42") != (have = (b[b.length-1] for b in sequence when b.length > 0).join('|'))
    console.log "HAVE - WANT:\n#{have}\n#{want}"
    throw new Error("unexpected sequence - please adjust expectation and/or sequence. See log for info.")


  it "should properly implement verticallyOppositeOf()", ->
    expect(verticallyOppositeOf above).toBe below
    expect(verticallyOppositeOf below).toBe above

  for key, direction of TraversalDirection
    ((direction) ->
      describe "traversal", ->
        beforeEach ->
          @cd = switch direction
            when previous then blockCache 0
            when next then blockCache sequence.length - 1
            else throw new Error("unknown direction: #{direction}")

          @c1 = blockCacheAt 'function', '_0fn'

        it "should initialize the cache on the cursor", ->
          b = @c1.cursor
          expect(b.$$locatedAt).toEqual {}
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
            for path in [['function', '_0fn'], ['function', '_1name']]
              c = blockCacheAt path
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
      for direction of TraversalDirection
        ((fnName, direction) ->
          describe "#{fnName}() to #{direction}", ->
            it "should setup direct siblings", ->
              c = blockCacheAt 'function', '_1name'
              lc = c.cursor
              b = c[fnName](direction)
              expect(lc.depth()).toBe b.depth()

              expect(lc.$$locatedAt[direction]).toBe b
              expect(b.$$locatedAt[oppositeOf direction]).toBe lc
              expect(b.$$locatedAt[direction]).toBeFalsy()

            it "should setup siblings when they become apparent", ->
              c = blockCacheAt 'function', '_2arguments', '1', 'mut x'
              lc = c.cursor
              b = c[fnName](direction)

              expect(b.depth()).toBe lc.depth() - 1
              expect(b.$$locatedAt[oppositeOf direction]).toBeUndefined()

              c.cursor = lc
              nb = c[fnName](oppositeOf direction)

              expect(nb.depth()).toBe lc.depth() - 1
              expect(nb.$$locatedAt[direction]).toBe b
              expect(b.$$locatedAt[oppositeOf direction]).toBe nb

            it "should setup direct parent/child relationships", ->
              c = blockCacheAt 'function', '_2arguments', '1'
              lc = c.cursor
              b = c[fnName](direction)
              expect(Math.abs(lc.depth() - b.depth())).toBe 1

              position = switch direction
                when next then below
                when previous then above
                else throw new Error("invalid direction: #{direction}")
              expect(lc.$$locatedAt[position]).toBe b
              expect(b.$$locatedAt[verticallyOppositeOf position]).toBe lc
              expect(b.$$locatedAt[position]).toBeFalsy()

        )(fnName, direction)
      ((fnName) ->
        describe "#{fnName}()", ->
          it "should setup indirect parent relationships", ->
            c = blockCacheAt 'function', '_2arguments', '2', 'usize'
            lc = c.cursor

            expect(lc.$$nextInSequenceAt[previous]).toBeUndefined()

            b = c[fnName](next)

            expect(lc.depth() - b.depth()).toBe 2
            expect(b.path()).toEqual ['function', '_return']

            expect(b.$$locatedAt[next]).toBeUndefined()
            expect(b.$$locatedAt[previous].path()).toEqual ['function', '_2arguments']

            expect(lc.$$nextInSequenceAt[next]).toBe b
            expect(lc.$$nextInSequenceAt[previous]).not.toBeUndefined()
            expect(b.$$nextInSequenceAt[previous]).toBe lc

            parent = b.$$locatedAt[above]
            expect(parent.depth()).toBe b.depth() - 1
            expect(parent.$$locatedAt[below]).toBe b

          it "should setup indirect child relationships", ->
      )(fnName)
