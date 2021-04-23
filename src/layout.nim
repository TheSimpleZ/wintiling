import winim/com
import window
import math
import sequtils
import sugar
import options
type
  LayoutKind* = enum
    Window, Container

  Direction* = enum
    Row, Column


  DesktopLayout*  = ref object
    width, height: int
    x, y: int
    case kind*: LayoutKind
      of Window:
        window*: Window
        isFocused*: bool
      of Container:
        children*: seq[DesktopLayout]
        growDirection*: Direction

proc allWindows*(self: DesktopLayout): seq[DesktopLayout] =
  if self.kind == Window:
    return @[self]
  else:
    return self.children.map(allWindows).foldl(a & b)

proc isFocused*(self: DesktopLayout): bool =
  if self.kind == Window:
    return self.isFocused
  else:
    return self.children.anyIt(it.isFocused)


proc setDimensions*(layout: DesktopLayout, width, height, x, y: int) =
  layout.width = width
  layout.height = height
  layout.x = x
  layout.y = y
  if layout.kind == Container:
    let mainAxisLen = if layout.growDirection == Row: layout.width
                      else: layout.height
    let childMainAxisLen = int floor mainAxisLen / layout.children.len
    for i, child in layout.children:
      let prevChild = if i == 0: DesktopLayout()
                      else: layout.children[i-1]
      if layout.growDirection == Row:
        child.setDimensions(childMainAxisLen, height,
                            prevChild.x + prevChild.width, y)
      else:
        child.setDimensions(width, childMainAxisLen, x,
                            prevChild.y + prevChild.height)


proc first*(self: DesktopLayout, cond: (DesktopLayout)->bool): Option[DesktopLayout] =
  if cond self:
    result = some self
  elif self.kind == Container:
    for child in self.children:
      result = child.first(cond)
      if result.isSome: break

proc walk*(self: DesktopLayout, kind: LayoutKind, operation: (DesktopLayout)->bool) =
  if self.kind == kind and not operation self: return
  elif self.kind == Container:
    for child in self.children:
      walk child, kind, operation





converter intToInt32(x: int): int32 = int32 x

proc render*(self: DesktopLayout) =
  let allWindows = self.allWindows
  var posStruct = BeginDeferWindowPos(int32 allWindows.len)
  for i, winLayout in allWindows:
      let prevWindow = if i == 0: HWND_BOTTOM
                       else: allWindows[i-1].window.nativeHandle
      posStruct = posStruct.DeferWindowPos(winLayout.window.nativeHandle, prevWindow,
                                          winLayout.x, winLayout.y,
                                          winLayout.width, winLayout.height,
                                          SWP_SHOWWINDOW)

  posStruct.EndDeferWindowPos()