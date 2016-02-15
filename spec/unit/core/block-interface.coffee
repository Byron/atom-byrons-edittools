{TraversalDirection, BlockInterface, oppositeOf} =
                                    require '../../../lib/core/block-interface'
ExampleBlock = require '../../utils/example-block'

describe "BlockInterface", ->
  test = assert = it
  v = null
  sequence =
    a: v
    b:
      a: v
      b:
        a: v,
    c: v

  sequence = ExampleBlock.makeSequenceDF sequence
  fakeEditor = {}
  {previous, next} = TraversalDirection

  beforeEach ->
    @b0 = new ExampleBlock sequence, 0
    @blast = new ExampleBlock sequence, sequence.length - 1

  describe 'ExampleBlock', ->
    it 'should flatten structures DF, keeping all encountered paths', ->
      expect(sequence[0]).toEqual []
      expect(sequence[sequence.length-1]).toEqual ['c']

    test 'path()', ->
      expect(@b0.path()).toEqual []
      expect(@blast.path()).toEqual ['c']

    test 'depth()', ->
      expect(@b0.depth(fakeEditor)).toBe 0
      expect(@blast.depth(fakeEditor)).toBe 1

  describe "BlockInterface", ->
    describe 'at()', ->
      it 'should return null if it reached the previous document border', ->
        expect(@b0.at previous, fakeEditor).toBe null

      it 'should return null if it reaches the next document border', ->
        expect(@blast.at next, fakeEditor).toBe null

      it 'should return the next block within the document', ->
        bnext = @b0.at next, fakeEditor
        expect(bnext.path()).toEqual ['a']
        expect(bnext.depth(fakeEditor)).toBe 1

      it 'should return the previous block within the document', ->
        bprev = @blast.at previous, fakeEditor
        expect(bprev.path()).toEqual ['b', 'b', 'a']
        expect(bprev.depth(fakeEditor)).toBe 3

    describe 'depth()', ->
      block = (index) -> new ExampleBlock sequence, index

      assert 'that siblings have similar depth', ->
        expect(block(1).depth(fakeEditor)).toBe block(2).depth(fakeEditor)

      assert 'that direct children increment depth by one', ->
        expect(block(2).depth(fakeEditor)).toBe block(3).depth(fakeEditor) - 1

      assert 'that direct parents decrement depth by one', ->
        expect(block(5).depth(fakeEditor)).toBe block(4).depth(fakeEditor) + 1

    describe 'range()', ->
      it "should always return a range object", ->
        r = @b0.range(fakeEditor)
        expect(r.start).toBeDefined()
        expect(r.end).toBeDefined()

describe "oppositeOf()", ->
  for key, direction of TraversalDirection
    ((direction) ->
      it "should return the oppisite direction", ->
        expect(oppositeOf direction).not.toEqual direction
    )(direction)
