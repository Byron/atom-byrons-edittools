{BlockCache} = require '../../lib/core/block-cache'
ExampleBlock = require './example-block'

makeBlockCacheBuilders = (sequence, editor) ->
  blockCache = (index) -> new BlockCache(new ExampleBlock(sequence, index),
                                         editor)
  blockCacheAt = (possiblyArray) ->
    args = if _.isString(possiblyArray) then (a for a in arguments)
    else possiblyArray

    index = _.findIndex sequence, (p) -> _.isEqual(p, args)
    if index < 0
      throw Error "invalid block path: #{(a for a in args).join('.')}"
    blockCache index

  {blockCacheAt, blockCache}

module.exports = {makeBlockCacheBuilders}
