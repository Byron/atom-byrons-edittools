{BlockCache, Relationship, oppositeOf, directionToRelation} =
                                        require('../../../lib/core/block-cache')
ExampleBlock = require '../../utils/example-block'
{TraversalDirection} = require '../../../lib/core/block-interface'
initMatchers = require './block-cache-matchers'
data = require '../../fixtures/data'
{makeBlockCacheBuilders} = require '../../utils/base'

toRelation = directionToRelation

describe "BlockCache", ->
  sequence = data.rustFn
  fakeEditor = ed = {}

  {previous, next} = TraversalDirection
  {parent, child, nextSibling, previousSibling} = Relationship

  {blockCache, blockCacheAt} = makeBlockCacheBuilders sequence, fakeEditor

  beforeEach ->
    initMatchers this

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
          b = @c1.cursor()
          expect(b.$cached).toEqual {}

        describe "advance() to #{direction}", ->
          it "advance and returns the cursor", ->
            lastCursor = @c1.cursor()
            expect(@c1.advance direction).toBe @c1.cursor()
            expect(@c1.cursor()).not.toBe lastCursor

          it "returns null if it reaches end of document and doesn't advance
              cursor", ->
            lastCursor = @cd.cursor()
            expect(@cd.advance direction).toBe null
            expect(@cd.cursor()).toBe lastCursor

          it "returns siblings, parents and children from cache", ->
            for path in [['function', '_0fn'], ['function', '_1name']]
              c = blockCacheAt path
              lc = c.cursor()
              c.advance direction
              expect(c.advance oppositeOf direction).toBe lc

        describe "peek() to #{direction}", ->
          it "must not change cursor when peeking", ->
            lastCursor = @c1.cursor()
            expect(@c1.peek direction).toBeTruthy()
            expect(@c1.cursor()).toBe lastCursor

          it "should return the same result if peeking multiple times", ->
            expect(@c1.peek direction).toBe @c1.peek direction

          it "returns null at the end of a document", ->
            expect(@cd.peek direction).toBe null

          it "peek results are consistent in the face of advance", ->
            lastCursor = @cd.cursor()
            peeked = @cd.peek oppositeOf direction
            expect(peeked).not.toEqual @cd.peek direction
            expect(nextCursor = @cd.advance oppositeOf direction).toBe peeked
            expect(@cd.peek direction).toBe lastCursor

            expect(@cd.advance direction).toBe lastCursor
            expect(@cd.peek oppositeOf direction).toBe nextCursor
    )(direction)

  describe "caching", ->
    saveTimeAndJustCheckAdvanceWhichCallsPeek = (a) ->
      n for n in a when 'advance' == n
    for fnName in saveTimeAndJustCheckAdvanceWhichCallsPeek ['peek', 'advance']
      for direction of TraversalDirection
        ((fnName, direction) ->
          describe "#{fnName}() to #{direction}", ->
            it "should setup direct siblings", ->
              c = blockCacheAt 'function', '_1name'
              lc = c.cursor()
              b = c[fnName](direction)
              expect(lc.depth(ed)).toBe b.depth(ed)

              expect(lc.cached direction).toBe b
              directionSibling = lc.cached toRelation direction
              expect(directionSibling).toBe b

              expect(b.cached oppositeOf direction).toBe lc
              oppositeSibling = b.cached toRelation oppositeOf direction
              expect(oppositeSibling).toBe lc
              expect(b.cached direction).toBeFalsy()

            it "can peek siblings separated by multiple traversal steps", ->
              lut =
                next: ['function', '_2arguments']
                previous: ['function', '_return']

              c = blockCacheAt lut[direction]
              lc = c.cursor()
              siblingRelation = toRelation direction
              otherSiblingRelation = oppositeOf siblingRelation

              b = c[fnName](siblingRelation)
              expect(b.path()).toEqual lut[oppositeOf direction]
              expect(lc.cached siblingRelation).toBe b
              expect(b.cached otherSiblingRelation).toBe lc

            it "peeking siblings past the end of the document yields null", ->
              c = setupCacheAtEndOfDocument(direction)

              expect(c[fnName](toRelation direction)).toBe null
              expect(c.cursor().cached toRelation direction).toBeUndefined()

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
              lc = c.cursor()
              b = c[fnName](direction)

              expect(b.depth(ed)).toBe lc.depth(ed) - 1
              oppositeSibling = b.cached toRelation oppositeOf direction
              expect(oppositeSibling).toBeUndefined()

              c.setCursor(lc)
              nb = c[fnName](oppositeOf direction)

              expect(nb.depth(ed)).toBe lc.depth(ed) - 1
              expect(nb.cached toRelation direction).toBe b
              expect(b.cached toRelation oppositeOf direction).toBe nb

            it "should setup direct parent/child relationships", ->
              c = blockCacheAt 'function', '_2arguments', '1'
              lc = c.cursor()
              b = c[fnName](direction)
              expect(Math.abs(lc.depth(ed) - b.depth(ed))).toBe 1

              position = switch direction
                when next then child
                when previous then parent
                else throw new Error("invalid direction: #{direction}")
              expect(lc.cached position).toBe b
              expect(b.cached oppositeOf position).toBe lc
              expect(b.cached position).toBeFalsy()

            it "to siblings relation", ->
              c = blockCacheAt 'function', '_1name'
              lc = c.cursor()
              siblingRelation = toRelation direction
              expect(lc.cached siblingRelation).toBeUndefined()

              b = c[fnName](siblingRelation)

              expect(lc.cached(siblingRelation).depth(ed)).toBe lc.depth(ed)
              expect(b.depth(ed)).toBe lc.depth(ed)
              expect(b.cached oppositeOf siblingRelation).toBe lc

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
            lc = c.cursor()

            expect(lc.cached previous).toBeUndefined()

            b = c[fnName](next)

            expect(lc.depth(ed) - b.depth(ed)).toBe 2
            expect(b.path()).toEqual ['function', '_return']

            expect(b.cached nextSibling).toBeUndefined()
            expect(b.cached(previousSibling).path()).toEqual ['function',
                                                                '_2arguments']

            expect(b).toBeNextOf lc
            expect(lc.cached previous).not.toBeUndefined()
            expect(lc).toBePreviousOf b

            p = b.cached parent
            expect(p.depth(ed)).toBe b.depth(ed) - 1
            expect(p.path()).toEqual ['function']
            expect(b).toBeChildOf(p)

          it "should setup indirect child relationships", ->
            c = blockCacheAt 'function', '_return'
            lc = c.cursor()

            expect(lc.cached previous).toBeUndefined()

            b = c[fnName](previous)

            parentPath = ['function', '_2arguments', '2']
            expect(lc.depth(ed) - b.depth(ed)).toBe - 2
            expect(b.path()).toEqual parentPath.concat ['usize']

            expect(b.cached nextSibling).toBeUndefined()
            siblingPath = parentPath.concat ['u32']
            expect(b.cached(previousSibling).path()).toEqual siblingPath

            expect(b).toBePreviousOf lc
            expect(lc.cached next).toBeUndefined()
            expect(lc).toBeNextOf b

            expect(b.cached(parent).path()).toEqual parentPath

          it "should find parents", ->
            c = blockCacheAt 'function', '_0fn'
            lc = c.cursor()
            b = c[fnName](parent)

            expect(b.path()).toEqual ['function']
            expect(b.cached child).toBe lc
            expect(b).toBeParentOf lc

          it "should return null parent at the root of the document", ->
            c = blockCacheAt []
            lc = c.cursor()
            b = c[fnName](parent)

            expect(b).toBe null
            expect(lc.cached parent).toBeUndefined()
            expect(lc.cached child).toBeUndefined()

          it "should obtain children", ->
            c = blockCacheAt ['function']
            lc = c.cursor()
            b = c[fnName](child)

            expect(lc).toBeParentOf b
            expect(b.cached child).toBeUndefined()
            expect(lc.cached child).toBe b
            expect(lc.cached parent).toBeUndefined()

          it "should return null child at the end of the document", ->
            c = setupCacheAtEndOfDocument(atTheVeryEnd)
            lc = c.cursor()
            b = c[fnName](child)

            expect(b).toBe null
            expect(lc.cached child).toBeUndefined()

          it "should return null if there is no child", ->
            c = blockCacheAt ['function', '_return', 'u8']
            lc = c.cursor()
            b = c[fnName](child)

            expect(b).toBe null
            expect(lc.cached child).toBeUndefined()

          it "should get no siblings when hitting the document boundary", ->
            c = blockCacheAt 'function'

            expect(c[fnName](nextSibling)).toBe null
            expect(c[fnName](previousSibling)).toBe null
      )(fnName)

  describe "setCursor()", ->
    beforeEach ->
      @c = blockCacheAt 'function'

    it "can set cursor to the same location", ->
      expect(@c.setCursor @c.cursor()).toBe @c

    it "can set cursor to block owned by same cache", ->
      b = @c.peek(child)

      expect(@c.setCursor(b)).toBe @c
      expect(@c.cursor()).toBe b

    it "can set cursor to an arbitrary block", ->
      b = new ExampleBlock(sequence, 0)
      expect(b.$cached).toBeUndefined()

      @c.setCursor b
      expect(b.$cached).not.toBeUndefined()

    it "can set cursor to block of other cache", ->
      b = blockCacheAt('function').cursor()
      pc = b.$cached
      expect(pc).not.toBeUndefined()

      @c.setCursor b
      expect(b.$cached).toBe pc
