_ = require 'lodash'

toSelect = (expected, editor) ->
  pass = false
  switch
    when not _.isString(expected)
      message = "need string, got '#{expected}'"
    when not _.isObject(editor)
      message = "second argument in expect clause must be editor instance"
    when not @actual.range?
      message = "input must be a Block providing the `range(..)`"
    else
      range = @actual.range editor
      text = @editor.getTextInBufferRange
      pass = text == expected
      if not pass
        message = "expected text in range #{range} to be
                  '#{expected}', found '#{text}'"

  @message = () -> message
  pass


initMatchers = (jasmine) ->
  jasmine.addMatchers {toSelect}

module.exports = initMatchers
