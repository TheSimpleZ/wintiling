import layout
import questionable
import win32/window

proc supressKey*(root, self: Desktop): bool = discard
proc printTree*(root, self: Desktop): bool =
  debugEcho root


proc moveWindowFocusLeft*(root, self: Desktop): bool =
  self.moveFocusTo(Left, root)
  result = false

proc moveWindowFocusRight*(root, self: Desktop): bool =
  self.moveFocusTo(Right, root)
  false

proc moveWindowFocusDown*(root, self: Desktop): bool =
  self.moveFocusTo(Down, root)
  false

proc moveWindowFocusUp*(root, self: Desktop): bool =
  self.moveFocusTo(Up, root)
  false

proc moveLeft*(root, self: Desktop): bool =
  if self.parent.value.orientation == Row:
    root.move self, Left
    return true

proc moveRight*(root, self: Desktop): bool =
  if self.parent.value.orientation == Row:
    root.move self, Right
    return true

proc moveDown*(root, self: Desktop): bool =
  if self.parent.value.orientation == Column:
    root.move self, Right
    return true

proc moveUp*(root, self: Desktop): bool =
  if self.parent.value.orientation == Column:
    root.move self, Left
    return true

proc transpose*(root, self: Desktop): bool =
  self.parent.value.orientation = if self.parent.isRow: Column else: Row
  for child in self.parent.children:
    child.value.orientation = self.parent.value.orientation
  return true

proc groupLeft*(root, self: Desktop): bool =
  if self.parent.value.orientation == Row:
    return self.groupWith(Left)
  else: layout.moveUp(self)

proc groupRight*(root, self: Desktop): bool =
  if self.parent.value.orientation == Row:
    return self.groupWith(Right)
  else: layout.moveUp(self)

proc groupDown*(root, self: Desktop): bool =
  if self.parent.value.orientation == Column:
    return self.groupWith(Down)
  else: layout.moveUp(self)

proc groupUp*(root, self: Desktop): bool =
  if self.parent.value.orientation == Column:
    return self.groupWith(Up)
  else: layout.moveUp(self)