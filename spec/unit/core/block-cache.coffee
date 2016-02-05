{BlockCache, Relationship, oppositeOf, directionToRelation} =
                                        require('../../../lib/core/block-cache')
ExampleBlock = require '../../utils/example-block'
{TraversalDirection} = require '../../../lib/core/block-interface'
_ = require 'lodash'
toRelation = directionToRelation

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
    if index < 0
      throw Error "invalid block path: #{(a for a in args).join('.')}"
    blockCache index

  want = "function|_0fn|_1name|_2arguments|1|mut x|2|u32|usize|_return|u8|\
          body|42"
  have = (b[b.length-1] for b in sequence when b.length > 0).join('|')
  if want != have
    console.log "HAVE - WANT:\n#{have}\n#{want}"
    throw new Error("unexpected sequence - please adjust expectation and/or
    sequence. See log for info.")


  it "should properly implement oppositeOf()", ->
    expect(oppositeOf parent).toBe child
    expect(oppositeOf child).toBe parent
    expect(oppositeOf next).toBe previous
    expect(oppositeOf previous).toBe next
    expect(oppositeOf nextSibling).toBe previousSibling
    expect(oppositeOf previousSibling).toBe nextSibling

  atTheVeryEnd = next
  setupCacheAtEndOfDocument = (direction) ->
    switch direction
      when next then blockCache sequence.length - 1
      when previous then blockCache 0
      else throw new Error("unknown direction: #{direction}")

  for key, direction of TraversalDirection
    ((direction) ->
      describe "traversal", ->
        beforeEach ->
          @cd = setupCacheAtEndOfDocument(direction)
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

          it "returns null if it reaches end of document and doesn't advance
              cursor", ->
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
            peeked = @cd.peek oppositeOf direction
            expect(peeked).not.toEqual @cd.peek direction
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
              directionSibling = lc.$$cached[toRelation direction]
              expect(directionSibling).toBe b

              expect(b.$$cached[oppositeOf direction]).toBe lc
              oppositeSibling = b.$$cached[toRelation oppositeOf direction]
              expect(oppositeSibling).toBe lc
              expect(b.$$cached[direction]).toBeFalsy()

            it "can peek siblings separated by multiple traversal steps", ->
              lut =
                next: ['function', '_2arguments']
                previous: ['function', '_return']

              c = blockCacheAt lut[direction]
              lc = c.cursor
              siblingRelation = toRelation direction
              otherSiblingRelation = oppositeOf siblingRelation

              b = c[fnName](siblingRelation)
              expect(b.path()).toEqual lut[oppositeOf direction]
              expect(lc.$$cached[siblingRelation]).toBe b
              expect(b.$$cached[otherSiblingRelation]).toBe lc

            it "peeking siblings past the end of the document yields null", ->
              c = setupCacheAtEndOfDocument(direction)

              expect(c[fnName](toRelation direction)).toBe null
              expect(c.cursor.$$cached[toRelation direction]).toBeUndefined()

            it "returns null if there is no sibling in that direction", ->
              prefix = ['function', '_2arguments']
              lut =
                next: prefix.concat ['2']
                previous: prefix.concat ['1']

              c = blockCacheAt lut[direction]
              b = c[fnName](toRelation direction)
              expect(b).toBe null

            it "should setup siblings when they become apparent", ->
              c = blockCacheAt 'function', '_2arguments', '1', 'mut x'
              lc = c.cursor
              b = c[fnName](direction)

              expect(b.depth()).toBe lc.depth() - 1
              oppositeSibling = b.$$cached[toRelation oppositeOf direction]
              expect(oppositeSibling).toBeUndefined()

              c.cursor = lc
              nb = c[fnName](oppositeOf direction)

              expect(nb.depth()).toBe lc.depth() - 1
              expect(nb.$$cached[toRelation direction]).toBe b
              expect(b.$$cached[toRelation oppositeOf direction]).toBe nb

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

            it "to siblings relation", ->
              c = blockCacheAt 'function', '_1name'
              lc = c.cursor
              siblingRelation = toRelation direction
              expect(lc.$$cached[siblingRelation]).toBeUndefined()

              b = c[fnName](siblingRelation)

              expect(lc.$$cached[siblingRelation].depth()).toBe lc.depth()
              expect(b.depth()).toBe lc.depth()
              expect(b.$$cached[oppositeOf siblingRelation]).toBe lc

        )(fnName, direction)

      ((fnName) ->
        describe "#{fnName}()", ->
          it "should bark on invalid direction", ->
            exceptionWasThrown = false
            try
              blockCache(0)[fnName]('myDirection or relation')
            catch e
              console.log e
              expect(e.toString()).toMatch "invalid direction"
              exceptionWasThrown = true

            expect(exceptionWasThrown).toBe true

          it "should setup indirect parent relationships", ->
            c = blockCacheAt 'function', '_2arguments', '2', 'usize'
            lc = c.cursor

            expect(lc.$$cached[previous]).toBeUndefined()

            b = c[fnName](next)

            expect(lc.depth() - b.depth()).toBe 2
            expect(b.path()).toEqual ['function', '_return']

            expect(b.$$cached[nextSibling]).toBeUndefined()
            expect(b.$$cached[previousSibling].path()).toEqual ['function',
                                                                '_2arguments']

            expect(lc.$$cached[next]).toBe b
            expect(lc.$$cached[previous]).not.toBeUndefined()
            expect(b.$$cached[previous]).toBe lc

            p = b.$$cached[parent]
            expect(p.depth()).toBe b.depth() - 1
            expect(p.path()).toEqual ['function']
            expect(p.$$cached[child]).toBe b

          it "should setup indirect child relationships", ->
            c = blockCacheAt 'function', '_return'
            lc = c.cursor

            expect(lc.$$cached[previous]).toBeUndefined()

            b = c[fnName](previous)

            parentPath = ['function', '_2arguments', '2']
            expect(lc.depth() - b.depth()).toBe - 2
            expect(b.path()).toEqual parentPath.concat ['usize']

            expect(b.$$cached[nextSibling]).toBeUndefined()
            siblingPath = parentPath.concat ['u32']
            expect(b.$$cached[previousSibling].path()).toEqual siblingPath

            expect(lc.$$cached[previous]).toBe b
            expect(lc.$$cached[next]).toBeUndefined()
            expect(b.$$cached[next]).toBe lc

            expect(b.$$cached[parent].path()).toEqual parentPath

          it "should find parents", ->
            c = blockCacheAt 'function', '_0fn'
            lc = c.cursor
            b = c[fnName](parent)

            expect(b.path()).toEqual ['function']
            expect(b.$$cached[child]).toBe lc
            expect(lc.$$cached[parent]).toBe b

          it "should return null parent at the root of the document", ->
            c = blockCacheAt []
            lc = c.cursor
            b = c[fnName](parent)

            expect(b).toBe null
            expect(lc.$$cached[parent]).toBeUndefined()
            expect(lc.$$cached[child]).toBeUndefined()

          it "should obtain children", ->
            c = blockCacheAt ['function']
            lc = c.cursor
            b = c[fnName](child)

            expect(b.$$cached[parent]).toBe lc
            expect(b.$$cached[child]).toBeUndefined()
            expect(lc.$$cached[child]).toBe b
            expect(lc.$$cached[parent]).toBeUndefined()

          it "should return null child at the end of the document", ->
            c = setupCacheAtEndOfDocument(atTheVeryEnd)
            lc = c.cursor
            b = c[fnName](child)

            expect(b).toBe null
            expect(lc.$$cached[child]).toBeUndefined()

          it "should return null if there is no child", ->
            c = blockCacheAt ['function', '_return', 'u8']
            lc = c.cursor
            b = c[fnName](child)

            expect(b).toBe null
            expect(lc.$$cached[child]).toBeUndefined()
      )(fnName)
