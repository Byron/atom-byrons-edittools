{Relationship} = require('../../../lib/core/block-cache')

piped = (p) -> p.join '|'

initMatchers = (jasmine) ->
  jasmine.addMatchers
    toBeChildOf: (expected) ->
      pass = false
      switch
        when !expected
          message = "expected block was '#{expected}'"
        when !this.actual
          message = "actual block was '#{@actual}'"
        else
          pass = expected.$$cached[Relationship.child] == @actual
          if pass
            message = "expected '#{piped @actual.path()}' to be child of
                             '#{piped expected.path()}'"

      @message = () -> message
      pass

module.exports = initMatchers
