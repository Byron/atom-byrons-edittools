{Direction, BlockInterface} = require '../../lib/block-interface'
{ExampleBlock, sequence} = require '../utils/example-block'

describe "BlockInterface", ->
  test = assert = it

  beforeEach ->
    @b0 = new ExampleBlock sequence, 0
    @blast = new ExampleBlock sequence, sequence.length - 1

  describe 'ExampleBlock', ->
    it 'should flatten structures depth first, keeping all encountered paths', ->
      expect(sequence[0]).toEqual []
      expect(sequence[sequence.length-1]).toEqual ['c']

    test 'path()', ->
      expect(@b0.path()).toEqual []
      expect(@blast.path()).toEqual ['c']

    test 'depth()', ->
      expect(@b0.depth()).toBe 0
      expect(@blast.depth()).toBe 1

  describe "BlockInterface", ->
    describe 'adjecentTo()', ->
      it 'should return null if it reached the left document border', ->
        expect(@b0.adjecentTo Direction.left).toBe null

      it 'should return null if it reaches the right document border', ->
        expect(@blast.adjecentTo Direction.right).toBe null

      it 'should return the right block within the document', ->
        bnext = @b0.adjecentTo(Direction.right)
        expect(bnext.path()).toEqual ['a']
        expect(bnext.depth()).toBe 1

      it 'should return the left block within the document', ->
        bprev = @blast.adjecentTo(Direction.left)
        expect(bprev.path()).toEqual ['b', 'b', 'a']
        expect(bprev.depth()).toBe 3

    describe 'depth()', ->
      block = (index) -> new ExampleBlock sequence, index

      assert 'that siblings have similar depth', ->
        expect(block(1).depth()).toBe block(2).depth()

      assert 'that direct children increment depth by one', ->
        expect(block(2).depth()).toBe block(3).depth() - 1

      assert 'that direct parents decrement depth by one', ->
        expect(block(5).depth()).toBe block(4).depth() + 1