import winim/com
import win32/window
import treenode
import std/with
import math
import sequtils
import options
type
  LayoutKind* = enum
    Window, Container

  Direction* = enum
    Row, Column

  Layout* = object
    width*, height*: int
    x*, y*: int
    case kind*: LayoutKind
      of Window:
        window*: Window
      of Container:
        growDirection*: Direction
  Desktop* = TreeNode[Layout]

converter intToInt32(x: int): int32 = int32 x

proc isWindow*(self: Desktop): bool = self.value.kind == Window
proc isContainer*(self: Desktop): bool = self.value.kind == Container
proc isRow*(self: Desktop): bool =
  self.isContainer and self.value.growDirection == Row


proc balanceDesktopDimensions(self: Desktop) =
  let borderThickness = GetSystemMetrics(SM_CXSIZEFRAME)
  let halfBorder = int round borderThickness/2
  self.walkIt:
    if it.value.kind == Container:
      let newWidth = int round it.value.width / it.children.len
      let newHeight = int round it.value.height / it.children.len
      let growDir = it.value.growDirection
      for i, child in it.children:
        case growDir:
          of Row:
            with child.value:
                width = newWidth + borderThickness + halfBorder
                height = it.value.height + halfBorder
                x = i * newWidth
                y = it.value.y
          of Column:
            with child.value:
                width = it.value.width
                height = newHeight + halfBorder
                x = it.value.x
                y = i * newHeight

proc render*(self: Desktop) =
  self.balanceDesktopDimensions()
  let allWindows = self.allIt(it.value.kind == Window).mapIt(it.value)

  var posStruct = BeginDeferWindowPos(int32 allWindows.len)
  for i, winLayout in allWindows:
      let prevWindow = if i == 0: HWND_BOTTOM
                       else: allWindows[i-1].window.nativeHandle
      posStruct = posStruct.DeferWindowPos(winLayout.window.nativeHandle, prevWindow,
                                          winLayout.x, winLayout.y,
                                          winLayout.width, winLayout.height,
                                          SWP_SHOWWINDOW)

  posStruct.EndDeferWindowPos()

proc newDesktop*(growDirection: Direction, width, height: int): Desktop =
  initTreeNode(Layout(
      kind: Container,
      growDirection: growDirection,
      width: width,
      height: height
    ))

proc dropDesktop*(self: Desktop) =
  self.drop()
  if not self.isRootNode:
    if self.parent.isContainer and self.parent.children.len == 0:
      self.parent.dropDesktop


converter toWindowLayout*(newWindow: Window): Layout =
  Layout(window: newWindow, kind: Window)

proc findFocusedWindow*(self: Desktop): Option[Desktop] =
  let foregroundWindow = getForegroundWindow()
  self.firstIt:
    it.value.kind == Window and it.value.window == foregroundWindow

proc findInvisibleWindows*(self: Desktop): seq[Desktop] =
  self.allIt:
    it.isWindow() and not it.value.window.isVisible

proc transpose*(self: Desktop) =
  self.value.growDirection = if self.isRow: Column else: Row
