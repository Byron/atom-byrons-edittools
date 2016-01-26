

# An interface to allow traversing anything that can be represented by a hierarchy.
#
# It deals with blocks, who have parents and children
class AsterVisitorInterface

  # Returns truthy value if selection succeeded.
  selectSiblingBlock: ({direction, mode}) ->
    throw new Error('to be implemented by subclass')

  # Returns an array of two {line: , column:} objects, representing the top left
  # and bottom-right bounds of the currently selected blocks in editor coordinates
  editorCoordinates: () ->
    throw new Error('to be implemented in subclass')


AsterVisitorInterface.direction =
  previousSibling: 'previousSibling',
  nextSibling: 'nextSibling',
  parent: 'parent',
  child: 'child'
AsterVisitorInterface.selectMode = add: 'add', remove: 'remove'
