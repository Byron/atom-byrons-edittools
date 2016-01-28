{Direction, Relation, BlockInterface} = require '../../lib/block-interface'
{isObject, keys, isArray, clone} = require 'lodash'

# block where traversal order is depth first
class ExampleBlock extends BlockInterface
  constructor: (@sequence, @index) ->
  adjecentTo: (direction) ->
    nextIndex = switch direction
      when Direction.left then @index - 1
      when Direction.right then @index + 1

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
