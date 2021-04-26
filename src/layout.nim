import winim/com
import window
import treenode
import std/with
import math
import sugar
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
        isFocused*: bool
      of Container:
        growDirection*: Direction
  Desktop* = TreeNode[Layout]

converter intToInt32(x: int): int32 = int32 x

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
    if self.parent.children.len == 0:
      self.parent.dropDesktop
    else:
      self.parent.children[0].value.isFocused = true

# proc leftDesktop*(self: Desktop): Option[Desktop] =
#   if not self.isRootNode:
#     let index = self.parent.children.find self
#     let leftIndex = index - 1
#     if leftIndex >= 0:
#       some self.parent.children[leftIndex]

converter toWindowLayout*(newWindow: Window): Layout =
  Layout(window: newWindow, kind: Window, isFocused: true)

proc isFocused*(self: Desktop): bool =
  if self.value.kind == Window:
    result = self.value.isFocused
  else:
    result = self.children.anyIt(it.isFocused)
