{BlockCache, Relationship, oppositeOf, directionToRelation} = require '../../lib/block-cache'
ExampleBlock = require '../utils/example-block'
{TraversalDirection} = require '../../lib/block-interface'
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
  {parent, child, nextSibling, previousSibling} = Relationship

  blockCache = (index) -> new BlockCache(new ExampleBlock(sequence, index))
  blockCacheAt = (first) ->
    args = if _.isString(first) then (a for a in arguments) else first
    index = _.findIndex sequence, (p) -> _.isEqual(p, args)
    throw Error "invalid block path: #{(a for a in args).join('.')}" if index < 0
    blockCache index

  if (want = "function|_0fn|_1name|_2arguments|1|mut x|2|u32|usize|_return|u8|body|42") != (have = (b[b.length-1] for b in sequence when b.length > 0).join('|'))
    console.log "HAVE - WANT:\n#{have}\n#{want}"
    throw new Error("unexpected sequence - please adjust expectation and/or sequence. See log for info.")


  it "should properly implement oppositeOf()", ->
    expect(oppositeOf parent).toBe child
    expect(oppositeOf child).toBe parent
    expect(oppositeOf next).toBe previous
    expect(oppositeOf previous).toBe next
    expect(oppositeOf nextSibling).toBe previousSibling
    expect(oppositeOf previousSibling).toBe nextSibling

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
          expect(b.$$cached).toEqual {}
          expect(b.$$cached).toEqual {}

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

              expect(lc.$$cached[direction]).toBe b
              expect(b.$$cached[oppositeOf direction]).toBe lc
              expect(b.$$cached[direction]).toBeFalsy()

            it "should setup siblings when they become apparent", ->
              c = blockCacheAt 'function', '_2arguments', '1', 'mut x'
              lc = c.cursor
              b = c[fnName](direction)

              expect(b.depth()).toBe lc.depth() - 1
              expect(b.$$cached[directionToRelation oppositeOf direction]).toBeUndefined()

              c.cursor = lc
              nb = c[fnName](oppositeOf direction)

              expect(nb.depth()).toBe lc.depth() - 1
              expect(nb.$$cached[directionToRelation direction]).toBe b
              expect(b.$$cached[directionToRelation oppositeOf direction]).toBe nb

            it "should setup direct parent/child relationships", ->
              c = blockCacheAt 'function', '_2arguments', '1'
              lc = c.cursor
              b = c[fnName](direction)
              expect(Math.abs(lc.depth() - b.depth())).toBe 1

              position = switch direction
                when next then child
                when previous then parent
                else throw new Error("invalid direction: #{direction}")
              expect(lc.$$cached[position]).toBe b
              expect(b.$$cached[oppositeOf position]).toBe lc
              expect(b.$$cached[position]).toBeFalsy()

        )(fnName, direction)
      ((fnName) ->
        describe "#{fnName}()", ->
          it "should setup indirect parent relationships", ->
            c = blockCacheAt 'function', '_2arguments', '2', 'usize'
            lc = c.cursor

            expect(lc.$$cached[previous]).toBeUndefined()

            b = c[fnName](next)

            expect(lc.depth() - b.depth()).toBe 2
            expect(b.path()).toEqual ['function', '_return']

            expect(b.$$cached[nextSibling]).toBeUndefined()
            expect(b.$$cached[previousSibling].path()).toEqual ['function', '_2arguments']

            expect(lc.$$cached[next]).toBe b
            expect(lc.$$cached[previous]).not.toBeUndefined()
            expect(b.$$cached[previous]).toBe lc

            p = b.$$cached[parent]
            expect(p.depth()).toBe b.depth() - 1
            expect(p.$$cached[child]).toBe b

          it "should setup indirect child relationships", ->
      )(fnName)
