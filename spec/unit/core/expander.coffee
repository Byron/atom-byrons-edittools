data = require '../../fixtures/data'
{makeBlockCacheBuilders} = require '../../utils/base'
{Expander, ExpansionDirection, BoundLocation} =
  require '../../../lib/core/expander'


describe "Expander", ->
  sequence = data.rustFn
  fakeEditor = {}

  {top, bottom} = BoundLocation
  {outward, inward} = ExpansionDirection

  {blockCache, blockCacheAt} = makeBlockCacheBuilders sequence, fakeEditor
  expanderAt = () -> new Expander blockCacheAt.apply(null, arguments)

  it "should keep its bounds at the cache cursor on init", ->
    e = expanderAt 'function', '_1name'
    origin = e.cache.cursor
    expect(origin).toBe e.$top
    expect(origin).toBe e.$bottom
    expect(origin).toBe e.cache.cursor

  describe "direct siblings", ->
    beforeEach ->
      @e = expanderAt 'function', '_1name'

    it "should grow outward equally towards top and bottom", ->
      r = @e.expand outward
      expect(r[top].path()).toEqual ['function', '_0fn']
      expect(r[bottom].path()).toEqual ['function', '_2arguments']

    it "should grow inward to the same location, cache results", ->
      r0 = @e.cursor()
      r1 = @e.expand outward
      r2 = @e.expand inward

      expect(r1).not.toEqual r2
      expect(r2).toEqual r0

    it "should return null if it cannot grow inward anymore", ->
      expect(@e.expand inward).toBe null

  describe "expansion blocked by hierarchy", ->

    beforeEach ->
      @origin = ['function', '_2arguments', '2']
      @e = expanderAt @origin

    it "should only grow top if bottom is blocked", ->
      expect(@e.cursor()[top].path()).toEqual @origin
      r = @e.expand outward
      expect(r[top].path()).toEqual ['function', '_2arguments', '1']
      expect(r[bottom].path()).toEqual @origin

    it "should grow to the parent if all siblings are taken", ->
      @e.expand outward
      r = @e.expand outward

      expect(r[top]).toEqual r[bottom]
      expect(r[top].path()).toEqual ['function', '_2arguments']

    it "should be able to shrink back to were it came from", ->
      r0 = @e.cursor()
      r1 = @e.expand outward
      @e.expand outward

      expect(@e.expand inward).toBe r1
      expect(@e.expand inward).toEqual r0

  describe "expansion blocked by document boundary", ->
    it "should grow top if bottom is blocked", ->
      e = expanderAt 'function', 'body'
      previousBottom = e.cursor()[bottom]
      r = e.expand outward

      expect(r[bottom]).toBe previousBottom
      expect(r[top].path()).toEqual ['function', '_return']

    it "should stop to grop if it is blocked at top", ->
      e = expanderAt []
      c = e.cursor()

      expect(e.expand outward).toEqual c
