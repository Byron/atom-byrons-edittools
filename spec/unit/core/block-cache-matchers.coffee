{Relationship} = require('../../../lib/core/block-cache')
{TraversalDirection} = require '../../../lib/core/block-interface'

_ = require 'lodash'

piped = (p) -> p.join '|'

makeRelationshipMatcher = (relation) ->
  (expected) ->
    pass = false
    switch
      when !expected
        message = "expected block was '#{expected}'"
      when !this.actual
        message = "actual block was '#{@actual}'"
      else
        pass = expected.$cached[relation] == @actual
        if !pass
          message = "expected '#{piped @actual.path()}' to be #{relation} of
                           '#{piped expected.path()}'"

    @message = () -> message
    pass


initMatchers = (jasmine) ->
  matchers = {}
  for relation in _.keys(Relationship).concat _.keys TraversalDirection
    relationName = _.capitalize relation
    matchers["toBe#{relationName}Of"] = makeRelationshipMatcher relation
  jasmine.addMatchers matchers

module.exports = initMatchers
