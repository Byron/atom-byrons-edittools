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
