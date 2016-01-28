BlockCache = require '../../lib/block-cache'
{ExampleBlock, sequence} = require '../utils/example-block'

describe "BlockCache", ->
  beforeEach ->
    @c = new BlockCache(new ExampleBlock sequence, 0)

  it 'should treat the first block as child of its (virtual) root', ->
    expect(@c.$root.$$children.length).toBe 1
