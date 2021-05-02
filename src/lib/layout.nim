import winim/com
import win32/window
import treenode
import std/with
import math
import sequtils
import questionable
import logging
import strformat

type
  LayoutKind* = enum
    Window, Container

  Orientation* = enum
    Row, Column

  Direction* = enum
    Backward = -1, Forward = 1

  Layout* = object
    width*, height*, x*, y*: int
    orientation*: Orientation
    case kind*: LayoutKind
      of Window: window*: Window
      of Container: discard

  Desktop* = TreeNode[Layout]

converter intToInt32(x: int): int32 = int32 x

proc isWindow*(self: Desktop): bool = self.value.kind == Window
proc isContainer*(self: Desktop): bool = self.value.kind == Container
proc isRow*(self: Desktop): bool = self.value.orientation == Row
proc isColumn*(self: Desktop): bool = self.value.orientation == Column

proc `$`*(self: Desktop, indent = "", last = true): string =
  let name = if self.isWindow: self.value.window.title
             else: fmt"Container {self.value.orientation}"
  let nextIndent = if last: "   "
                   else: "  |  "
  result = fmt("{indent} +- {name} (w:{self.value.width}, h:{self.value.height}, x:{self.value.x}, y:{self.value.y}) \n")

  for i, child in self.children:
    result.add `$`(child, indent & nextIndent, i == self.children.len)

proc balanceDesktopDimensions(self: Desktop) =
  # let borderThickness = GetSystemMetrics(SM_CXSIZEFRAME)
  # let halfBorder = int round borderThickness/2
  self.walkIt:
    if it.value.kind == Container:
      let newWidth = int round it.value.width / it.children.len
      let newHeight = int round it.value.height / it.children.len
      let growDir = it.value.orientation
      for i, child in it.children:
        case growDir:
          of Row:
            with child.value:
                width = newWidth #+ borderThickness # + halfBorder
                height = it.value.height #+ halfBorder
                x = it.value.x + i * newWidth
                y = it.value.y
          of Column:
            with child.value:
                width = it.value.width
                height = newHeight # + halfBorder
                x = it.value.x
                y = it.value.y + i * newHeight

proc render*(self: Desktop) =
  self.balanceDesktopDimensions()
  debug '\n', $self
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

proc newDesktop*(orientation: Orientation, width, height: int): Desktop =
  initTreeNode(Layout(
      kind: Container,
      orientation: orientation,
      width: width,
      height: height
    ))

proc newDesktop*(orientation: Orientation, parent: Desktop, width, height: int, children: seq[Desktop] = @[]): Desktop =
  initTreeNode(Layout(
      kind: Container,
      orientation: orientation,
      width: width,
      height: height
    ), parent, children)

proc copyToGrandParent(self: Desktop) =
  if not self.isRootNode and not self.parent.isRootNode:
    var closestGrandParnet: Desktop = self.parent.parent
    # If grandparent is nil because of drop, continue climb
    while not closestGrandParnet.isRootNode and
          not closestGrandParnet.parent.children.contains(closestGrandParnet):
        closestGrandParnet = closestGrandParnet.parent
    closestGrandParnet.add self

proc dropDesktop*(self: Desktop) =
  self.drop()
  if not self.isRootNode and
    self.parent.isContainer and
    self.parent.children.len < 2:
        if self.parent.children.len == 1:
          self.parent.children[0].copyToGrandParent()
        self.parent.dropDesktop()
  if self.isRootNode and self.children.len == 1:
    let child = self.children[0]
    if child.isContainer:
      child.dropDesktop()
      for grandChild in child.children:
        grandChild.copyToGrandParent()


converter toWindowLayout*(newWindow: Window): Layout =
  Layout(kind: Window, window: newWindow)

proc findFocusedWindow*(self: Desktop): ?Desktop =
  let foregroundWindow = getForegroundWindow()
  self.firstIt:
    it.value.kind == Window and it.value.window == foregroundWindow

proc allWindows(self: Desktop): seq[Window] =
  result = self.allIt(it.isWindow).mapIt(it.value.window)


proc findWindows*(self: Desktop, visible = true): seq[Desktop] =
  self.allIt:
    it.isWindow() and not(it.value.window.isVisible xor visible)

proc moveUp(self: Desktop) =
  if not self.isRootNode and not self.parent.isRootNode:
    self.dropDesktop()
    self.copyToGrandParent()


proc move*(root, self: Desktop, dir: Direction) =
  if not self.isRootNode:
    let allSiblings = self.parent.children
    let index = allSiblings.find(self)
    if index < 0: return

    let nextIndex = clamp(index + ord(dir), 0, allSiblings.len-1)

    if index != nextIndex:
      swap self.parent.children[nextIndex], self.parent.children[index]


proc moveWindowFocus*(root, self: Desktop; dir: Direction) =
  let allWindows = root.allWindows()
  let currentFocus = allWindows.find getForegroundWindow()
  let newFocus = clamp(currentFocus+ord(dir), 0, allWindows.len-1)

  let targetHwnd = allWindows[newFocus]

  targetHwnd.setForegroundWindow()

proc groupWith*(self: Desktop; dir: Direction): bool =
  result = true
  var allSiblings = self.parent.children
  let index = allSiblings.find(self)
  if index < 0: return
  let siblingIndex = clamp(index + ord(dir), 0, allSiblings.len-1)
  let sibling = allSiblings[siblingIndex]
  if self == sibling:
    moveUp(self)
    return true
  if sibling.isWindow:
    if self.parent.children.len <= 2: return false
    var previousParent = self.parent
    self.drop()
    sibling.drop()

    let children = if index > siblingIndex: @[sibling, self]
                   else: @[self, sibling]

    let container = newDesktop(self.value.orientation, self.parent,
      self.value.width + sibling.value.width,
      self.value.height + sibling.value.height, children
    )
    with container.value:
      x = sibling.value.x
      y = sibling.value.y
    while not previousParent.isRootNode and
          not previousParent.parent.children.contains(previousParent):
        previousParent = previousParent.parent
    previousParent.insert(container, index)
    # debugEcho '\n', $self.parent.parent

  else:
    # debugEcho '\n', $self.parent
    self.drop()
    if index > siblingIndex:
      sibling.add self
    else:
      sibling.insert self, 0

    # debugEcho '\n', $self.parent

    # debugEcho '\n', $self.parent
