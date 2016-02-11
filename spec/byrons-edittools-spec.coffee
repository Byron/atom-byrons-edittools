describe "unit", ->
  describe "core", ->
    require './unit/core/block-interface'
    require './unit/core/block-cache'
    require './unit/core/expander'
describe "integration", ->
  describe "blocks", ->
    require './integration/blocks/text.plain'
