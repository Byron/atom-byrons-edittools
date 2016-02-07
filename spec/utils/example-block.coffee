{TraversalDirection, Relation, BlockInterface} =
                                        require '../../lib/core/block-interface'
{isObject, keys, isArray, clone} = require 'lodash'
{previous, next} = TraversalDirection

# block where traversal order is depth first
class ExampleBlock extends BlockInterface
  constructor: (@sequence, @index) ->
  at: (direction, editor) ->
    throw new Error "need editor" unless editor?
    nextIndex = switch direction
      when previous then @index - 1
      when next then @index + 1
      else throw new Error("invalid direction: #{direction}")

    return null if nextIndex >= @sequence.length || nextIndex < 0

    new ExampleBlock @sequence, nextIndex

  path: () -> @sequence[@index]
  depth: () -> @path().length

  @makeSequenceDF: (structure) ->
    sequence = []
    keep = (item) -> sequence.push clone item
    traverse = (item, path=[]) ->
      keep path
      if isObject item
        k = keys item
        k.sort()
        for key in k
          path.push key
          traverse item[key], path
          path.pop()
      else if isArray item
        for obj, index in item
          path.push "[#{index}]"
          traverse(obj, path)
          path.pop()
      return
    traverse(structure)
    sequence

module.exports = ExampleBlock
