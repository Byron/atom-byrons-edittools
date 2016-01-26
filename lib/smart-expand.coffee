{CompositeDisposable} = require 'atom'

module.exports = SmartExpand =
  smartExpandView: null
  subscriptions: null

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'smart-expand:init': => @init()

  deactivate: ->
    @subscriptions.dispose()

  init: ->
    console.log 'SmartExpand was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
