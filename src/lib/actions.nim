import layout
import questionable
import win32/window

proc supressKey*(root, self: Desktop): bool = discard
proc printTree*(root, self: Desktop): bool =
  debugEcho root


proc move_window_focus_left*(root, self: Desktop): bool =
  self.moveFocusTo(Left, root)
  result = false

proc move_window_focus_right*(root, self: Desktop): bool =
  self.moveFocusTo(Right, root)
  false

proc move_window_focus_down*(root, self: Desktop): bool =
  self.moveFocusTo(Down, root)
  false

proc move_window_focus_up*(root, self: Desktop): bool =
  self.moveFocusTo(Up, root)
  false

proc move_window_left*(root, self: Desktop): bool =
  if self.parent.value.orientation == Row:
    root.move self, Left
    return true

proc move_window_right*(root, self: Desktop): bool =
  if self.parent.value.orientation == Row:
    root.move self, Right
    return true

proc move_window_down*(root, self: Desktop): bool =
  if self.parent.value.orientation == Column:
    root.move self, Right
    return true

proc move_window_up*(root, self: Desktop): bool =
  if self.parent.value.orientation == Column:
    root.move self, Left
    return true

proc transpose*(root, self: Desktop): bool =
  self.parent.value.orientation = if self.parent.isRow: Column else: Row
  for child in self.parent.children:
    child.value.orientation = self.parent.value.orientation
  return true

proc group_with_left_window*(root, self: Desktop): bool =
  if self.parent.value.orientation == Row:
    return self.groupWith(Left)
  else: layout.moveUp(self)

proc group_with_right_window*(root, self: Desktop): bool =
  if self.parent.value.orientation == Row:
    self.groupWith(Right)
  else: layout.moveUp(self)

proc group_with_window_below*(root, self: Desktop): bool =
  if self.parent.value.orientation == Column:
    self.groupWith(Down)
  else: layout.moveUp(self)

proc group_with_window_above*(root, self: Desktop): bool =
  if self.parent.value.orientation == Column:
    self.groupWith(Up)
  else: layout.moveUp(self)