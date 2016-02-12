describe "unit", ->
  describe "core", ->
    require './unit/core/block-interface'
    require './unit/core/block-cache'
    require './unit/core/expander'
    require './unit/core/point'
describe "integration", ->
  describe "blocks", ->
    require './integration/blocks/text.plain'
