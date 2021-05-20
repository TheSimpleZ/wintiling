import winim/com
import win32/window
import treenode
import std/with
import math
import sequtils
import questionable
import strformat
import algorithm
import options
import std/monotimes
import times


type
  LayoutKind* = enum
    Window, Container

  Orientation* = enum
    Row, Column

  HorizontalDirection* = enum
    Left = -1, Right = 1

  VerticalDirection* = enum
    Up = -1, Down = 1

  Direction* = HorizontalDirection or VerticalDirection

  Layout* = object
    width*, height*, x*, y*: int
    orientation*: Orientation
    case kind*: LayoutKind
      of Window: window*: Window
      of Container: discard

  Desktop* = TreeNode[Layout]

using
  self: Desktop
  root: Desktop
  dir: Direction



converter intToInt32(x: int): int32 = int32 x

proc isWindow*(self): bool = self.value.kind == Window
proc isContainer*(self): bool = self.value.kind == Container
proc isRow*(self): bool = self.value.orientation == Row
proc isColumn*(self): bool = self.value.orientation == Column

proc `$`*(self; indent = "", last = true): string =
  let name = if self.isWindow: self.value.window.title
             else: fmt"Container {self.value.orientation}"

  result = fmt"{name} (w:{self.value.width}, h:{self.value.height}, x:{self.value.x}, y:{self.value.y})"

  # if self.children.len > 0:
  result = fmt("{indent} +- {result} \n")

  let nextIndent = if last: "   "
                   else: "  |  "

  for i, child in self.children:
    result.add `$`(child, indent & nextIndent, i == self.children.len)

proc balanceDesktopDimensions(self) =
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

var last_invocation: MonoTime
proc render*(self) =
  let currentTime = getMonoTime()
  if last_invocation.ticks != 0 and
     currentTime - last_invocation < initDuration(milliseconds = 100):
    return
  last_invocation = currentTime

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

proc newDesktop*(orientation: Orientation, width, height: int): Desktop =
  newTreeNode(Layout(
      kind: Container,
      orientation: orientation,
      width: width,
      height: height
    ))

proc newDesktop*(orientation: Orientation, parent: Desktop, width, height: int, children: seq[Desktop] = @[]): Desktop =
  newTreeNode(Layout(
      kind: Container,
      orientation: orientation,
      width: width,
      height: height
    ), parent, children)

proc closestValidAncestor(self): ?Desktop =
  if not self.isRootNode and not self.parent.isRootNode:
    var closestAncestor: Desktop = self.parent.parent
    # If grandparent is nil because of drop, continue climb
    while not closestAncestor.isRootNode and
          not closestAncestor.parent.children.contains(closestAncestor):
        closestAncestor = closestAncestor.parent

    if closestAncestor.isRootNode or closestAncestor.parent.children.contains(closestAncestor):
      result = some closestAncestor

proc copyToGrandParent(self) =
  if not self.isRootNode and not self.parent.isRootNode:
    if ancestor =? self.closestValidAncestor():
      ancestor.add self

proc dropDesktop*(self) =
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

proc findFocusedWindow*(self): ?Desktop =
  let foregroundWindow = getForegroundWindow()
  self.firstIt:
    it.value.kind == Window and it.value.window == foregroundWindow


proc findWindows*(self; visible = true): seq[Desktop] =
  self.allIt:
    it.isWindow() and not(it.value.window.isVisible xor visible)


proc isInArea(self; rect: tuple[x, y, width, height: int]): bool =
  let val = self.value
  let (x, y, width, height) = rect
  result = not(
    val.x + val.width <= x or
    x + width <= val.x or
    val.y + val.height <= y or
    y + height <= val.y
  )

proc closestWindow(self, dir): proc (x, y: Desktop): int =
  result = proc (a, b: Desktop): int =
    when dir is HorizontalDirection:
      result = cmp(abs(self.value.x - a.value.x), abs(self.value.x - b.value.x))
    else:
      result = cmp(abs(self.value.y - a.value.y), abs(self.value.y - b.value.y))

proc getWindowTo*(self, dir, root): ?Desktop =
  let windows = root.findWindows()
  let val = self.value
  let searchX = when dir is HorizontalDirection:
                  val.x + val.width * ord(dir)
                else: val.x
  let searchY = when dir is VerticalDirection:
                  val.y + val.height * ord(dir)
                else: val.y
  var adjacentWindows = windows.filterIt:
    it != self and
    it.isInArea (searchX, searchY, val.width, val.height)

  adjacentWindows.sort(self.closestWindow(dir))

  if adjacentWindows.len > 0:
    result = some adjacentWindows[0]

proc moveUp*(self, dir): bool =
  if not self.isRootNode and not self.parent.isRootNode:
    result = true
    if self.parent.children.len < 3:
      for sibling in self.parent.children:
        if sibling.isWindow:
          sibling.value.orientation = self.parent.parent.value.orientation
      self.parent.delete()
    else:
      self.drop()
      self.value.orientation = self.parent.parent.value.orientation
      var nextIndex = self.parent.nodeIndex
      if ord(dir) == 1: inc nextIndex
      self.parent.parent.insert(self, nextIndex)


proc move*(root, self, dir) =
  if not self.isRootNode:
    if si =? self.siblingIndex(SiblingDirection dir):
        swap(
          self.parent.children[si],
          self.parent.children[self.nodeIndex]
        )


proc moveFocusTo*(self, dir, root) =
  if win =? self.getWindowTo(dir, root):
    setForegroundWindow win.value.window

proc wrapInContainer(children: seq[Desktop]): Desktop =
  let self = children[0]
  if not self.isRootNode:
    let width = children.mapIt(it.value.width).foldl(a+b)
    let height = children.mapIt(it.value.height).foldl(a+b)
    result = newDesktop(self.value.orientation, self.parent,
      width, height, @children
    )
    with result.value:
      x = self.value.x
      y = self.value.y

proc groupWith*(self, dir): bool =
  result = true
  let opts = self.findSibling(SiblingDirection dir)
  if opts.isSome:
    let sibling = opts.get()
    let index = self.nodeIndex
    let siblingIndex = sibling.nodeIndex
    if sibling.isWindow:
      if self.parent.children.len <= 2: return false
      let children = if index > siblingIndex: @[sibling, self]
                     else: @[self, sibling]
      let previousParent = self.parent
      self.drop()
      sibling.drop()
      let container = wrapInContainer(children)
      previousParent.insert(container, min(index, siblingIndex))

    else:
      self.drop()
      self.value.orientation = sibling.value.orientation
      if index > siblingIndex:
        sibling.add self
      else:
        sibling.insert self, 0

      if self.parent.allSiblings.len < 2:
        if self.parent.isRootNode and self.parent.children.len == 1:
          let child = self.parent.children[0]
          if child.isContainer:
            child.drop()
            for grandChild in child.children:
              self.parent.add(grandChild)
        else:
          self.parent.delete()

  elif not self.isRootNode and not self.parent.isRootNode and
      self.value.orientation == self.parent.parent.value.orientation:
    result = moveUp(self, dir)