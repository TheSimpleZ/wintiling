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
  let nextIndent = if last: "   "
                   else: "  |  "
  result = fmt"{name} (w:{self.value.width}, h:{self.value.height}, x:{self.value.x}, y:{self.value.y})"

  if self.children.len > 0:
    result = fmt("{indent} +- {result} \n")


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

proc render*(self) =
  self.balanceDesktopDimensions()
  # debug '\n', $self
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



proc copyToGrandParent(self) =
  if not self.isRootNode and not self.parent.isRootNode:
    var closestGrandParnet: Desktop = self.parent.parent
    # If grandparent is nil because of drop, continue climb
    while not closestGrandParnet.isRootNode and
          not closestGrandParnet.parent.children.contains(closestGrandParnet):
        closestGrandParnet = closestGrandParnet.parent
    closestGrandParnet.add self

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

proc allWindows(self): seq[Window] =
  result = self.allIt(it.isWindow).mapIt(it.value.window)


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

proc moveUp*(self) =
  if not self.isRootNode and not self.parent.isRootNode:
    self.dropDesktop()
    self.copyToGrandParent()

proc move*(root, self, dir) =
  if not self.isRootNode:
    if si =? self.siblingIndex(SiblingDirection dir):
        mixin si
        swap(
          self.parent.children[si],
          self.parent.children[self.nodeIndex]
        )


proc moveFocusTo*(self, dir, root) =
  let winOpts = self.getWindowTo(dir, root)
  if winOpts.isSome:
    let win = winOpts.get()
    win.value.window.setForegroundWindow()

proc groupWith*(self, dir): bool =
  result = true
  var allSiblings = self.parent.children
  let index = allSiblings.find(self)
  if index < 0: return
  let siblingIndex = clamp(index + ord(dir), 0, allSiblings.len-1)
  let opts = self.findSibling(SiblingDirection dir)
  if opts.isSome:
    let sibling = opts.get()
    # if self == sibling:
    #   moveUp(self)
    #   return true
    if isWindow sibling:
      if self.parent.children.len <= 2: return false
      var previousParent = self.parent
      self.drop()
      drop(sibling)

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

    else:
      self.drop()
      if index > siblingIndex:
        sibling.add self
      else:
        sibling.insert self, 0