import layout
import questionable
import win32/[window, keyboard]
import winim/lean
import windows_virtual_desktops
import tables

template move_window_focus*(dir: Direction): untyped =
  proc inner(root, self: Desktop): bool {.gensym.} =
    self.moveFocusTo(dir, root)
    result = false
  inner

template move_window*(dir: Direction): untyped =
  proc inner(root, self: Desktop): bool {.gensym.} =
    root.move self, dir
    result = true
  inner

template group_with*(dir: HorizontalDirection): untyped =
  proc inner(root, self: Desktop): bool {.gensym.} =
    if self.parent.value.orientation == Row:
      self.groupWith(dir)
    else: layout.moveUp(self, dir)
  inner

template group_with*(dir: VerticalDirection): untyped =
  proc inner(root, self: Desktop): bool {.gensym.} =
    if self.parent.value.orientation == Column:
      self.groupWith(dir)
    else: layout.moveUp(self, dir)
  inner

proc transpose*(root, self: Desktop): bool =
  self.parent.value.orientation = if self.parent.isRow: Column else: Row
  for child in self.parent.children:
    if child.isWindow:
      child.value.orientation = self.parent.value.orientation
  return true

proc supressKey*(root, self: Desktop): bool = discard

proc printTree*(root, self: Desktop): bool =
  debugEcho root

template send_to_desktop*(dir: HorizontalDirection): untyped =
  proc inner(root, self: Desktop): bool {.gensym.} =
    result = false
    let currentDesktop = GetCurrentDesktopNumber()
    let desktopCount = GetDesktopCount()
    var nextDesktop = currentDesktop + ord(dir)
    if nextDesktop < 0:
      return false

    if nextDesktop == desktopCount:
      nextDesktop = CreateVirtualDesktop()

    if self.isWindow:
      let win = self.value.window.nativeHandle
      discard MoveWindowToDesktopNumber(win, nextDesktop)
      GoToDesktopNumber nextDesktop
  inner
