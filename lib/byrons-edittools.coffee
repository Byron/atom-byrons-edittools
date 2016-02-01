{CompositeDisposable} = require 'atom'

module.exports = ByronsEditTools =

  activate: (state) ->
    @subscriptions = new CompositeDisposable

  deactivate: ->
    @subscriptions.dispose()
