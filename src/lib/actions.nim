import layout

proc supressKey*(root, self: Desktop): bool = discard

proc moveWindowFocusLeft*(root, self: Desktop): bool =
  if self.parent.value.orientation == Row:
    root.moveWindowFocus(self, Backward)
  false

proc moveWindowFocusRight*(root, self: Desktop): bool =
  if self.parent.value.orientation == Row:
    root.moveWindowFocus(self, Forward)
  false

proc moveWindowFocusDown*(root, self: Desktop): bool =
  if self.parent.value.orientation == Column:
    root.moveWindowFocus(self, Forward)
  false

proc moveWindowFocusUp*(root, self: Desktop): bool =
  if self.parent.value.orientation == Column:
    root.moveWindowFocus(self, Backward)
  false

proc moveLeft*(root, self: Desktop): bool =
  if self.parent.value.orientation == Row:
    root.move self, Backward
    return true

proc moveRight*(root, self: Desktop): bool =
  if self.parent.value.orientation == Row:
    root.move self, Forward
    return true

proc moveDown*(root, self: Desktop): bool =
  if self.parent.value.orientation == Column:
    root.move self, Forward
    return true

proc moveUp*(root, self: Desktop): bool =
  if self.parent.value.orientation == Column:
    root.move self, Backward
    return true

proc transpose*(root, self: Desktop): bool =
  self.parent.value.orientation = if self.parent.isRow: Column else: Row
  for child in self.parent.children:
    child.value.orientation = self.parent.value.orientation
  return true

proc groupLeft*(root, self: Desktop): bool =
  if self.parent.value.orientation == Row:
    return self.groupWith(Backward)

proc groupRight*(root, self: Desktop): bool =
  if self.parent.value.orientation == Row:
    return self.groupWith(Forward)

proc groupDown*(root, self: Desktop): bool =
  if self.parent.value.orientation == Column:
    return self.groupWith(Forward)

proc groupUp*(root, self: Desktop): bool =
  if self.parent.value.orientation == Column:
    return self.groupWith(Backward)