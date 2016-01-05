SmartExpandView = require './smart-expand-view'
{CompositeDisposable} = require 'atom'

module.exports = SmartExpand =
  smartExpandView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @smartExpandView = new SmartExpandView(state.smartExpandViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @smartExpandView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'smart-expand:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @smartExpandView.destroy()

  serialize: ->
    smartExpandViewState: @smartExpandView.serialize()

  toggle: ->
    console.log 'SmartExpand was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
