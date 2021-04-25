import winim/com
import window
import math
import sequtils
import sugar
import options
import tree
type
  LayoutKind* = enum
    Window, Container

  Direction* = enum
    Row, Column

  DesktopLayoutRef* = ref object
    width*, height*: int
    x*, y*: int
    case kind*: LayoutKind
      of Window:
        window*: Window
        isFocused*: bool
      of Container:
        growDirection*: Direction
  DesktopLayout* = Tree[DesktopLayoutRef]

proc newWindowLayout*(window: Window, isFocused = false): DesktopLayout =
  let newLayout = DesktopLayoutRef(
      kind: Window,
      window: window,
      isFocused: isFocused
    )
  initTree(newLayout)

proc newContainerLayout*(children: seq[DesktopLayout], growDirection: Direction,
                        width, height: int): DesktopLayout =
  let newLayout = DesktopLayoutRef(
      kind: Container,
      growDirection: growDirection
    )
  initTree(newLayout, children)

proc allWindows*(self: DesktopLayout): seq[DesktopLayout] =
  self.all do (node: DesktopLayout) -> bool:
    node.value.kind == Window

proc isFocused*(self: DesktopLayout): bool =
  if self.value.kind == Window:
    result = self.value.isFocused
  else:
    result = self.children.anyIt(it.isFocused)

proc setDimensionsRecurse(self: DesktopLayout, width, height, x, y: int = 0) =
  self.value.width = width
  self.value.height = height
  self.value.x = x
  self.value.y = y
  if self.value.kind == Container:
    let mainAxisLen = if self.value.growDirection == Row: self.value.width
                      else: self.value.height
    let childMainAxisLen = int floor mainAxisLen / self.children.len
    for i, child in self.children:
      let prevChild = if i == 0: self
                                     else: self.children[i-1]
      if self.value.growDirection == Row:
        child.setDimensionsRecurse(childMainAxisLen, height,
                                  prevChild.value.x + prevChild.value.width, y)
      else:
        child.setDimensionsRecurse(width, childMainAxisLen, x,
                                  prevChild.value.y + prevChild.value.height)

proc setDimensions(self: DesktopLayout) =
  self.setDimensionsRecurse(self.value.width, self.value.height, self.value.x, self.value.y)


converter intToInt32(x: int): int32 = int32 x

proc render*(self: DesktopLayout) =
  self.setDimensions()
  let allWindows = self.allWindows.mapIt(it.value)
  var posStruct = BeginDeferWindowPos(int32 allWindows.len)
  for i, winLayout in allWindows:
      let prevWindow = if i == 0: HWND_BOTTOM
                       else: allWindows[i-1].window.nativeHandle
      posStruct = posStruct.DeferWindowPos(winLayout.window.nativeHandle, prevWindow,
                                          winLayout.x, winLayout.y,
                                          winLayout.width, winLayout.height,
                                          SWP_SHOWWINDOW)

  posStruct.EndDeferWindowPos()