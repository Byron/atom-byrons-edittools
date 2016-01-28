BlockCache = require '../../lib/block-cache'
ExampleBlock = require '../utils/example-block'

describe "BlockCache", ->
  beforeEach ->
    @c = new BlockCache(new ExampleBlock [], 0)

  it 'should treat the first block as child of its (virtual) root', ->
    expect(@c.$root.$$children.length).toBe 1
