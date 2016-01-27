{Direction, Relation, BlockInterface} = require '../../lib/block-interface'
ExampleBlock = require './example-block'

describe "BlockInterface", ->
  v = null
  test = it
  root =
    a: v
    b:
      a: v
      b:
        a: v,
        b: v
      c: v

  sequence = ExampleBlock.makeSequenceDF root

  describe 'ExampleBlock', ->
    it 'should flatten structures depth first, keeping all encountered paths', ->
      expect(sequence[0]).toEqual []
      expect(sequence[7]).toEqual ['b', 'c']

  describe "BlockInterface", ->
    beforeEach ->
      @b0 = new ExampleBlock sequence, 0
      @blast = new ExampleBlock sequence, sequence.length - 1

    test 'adjecentTo()', ->
      expect(@b0.adjecentTo Direction.left).toBe null
      expect(@blast.adjecentTo Direction.right).toBe null

      expect(@b0.adjecentTo(Direction.right).path()).toEqual ['a']
      expect(@blast.adjecentTo(Direction.left).path()).toEqual ['b', 'b', 'b']
