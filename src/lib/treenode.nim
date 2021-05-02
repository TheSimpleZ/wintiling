import winim/com
import sequtils
import macros
import sugar
import options
import lists
type
  TreeNode*[T] = ref object of RootObj
    value*: T
    children*: seq[TreeNode[T]]
    case isRootNode: bool
    of false: parent*: TreeNode[T]
    of true: discard

proc `$`*(self: TreeNode, indent = "", last = true): string =
  let name = if self.isWindow: self.value.window.title
             else: "Container"
  let nextIndent = if last: "   "
                   else: "|  "
  result = indent & "+- " & name & '\n'

  for i, child in self.children:
    result.add `$`(child, indent & nextIndent, i == self.children.len)

proc initTreeNode*[T](nodeVal: T): TreeNode[T] =
  result = TreeNode[T](value: nodeVal, isRootNode: true)


proc initTreeNode*[T](nodeVal: T, parent: TreeNode[T],
                    children: seq[TreeNode[T]] = @[]): TreeNode[T] =
  result = TreeNode[T](
    value: nodeVal,
    isRootNode: false,
    parent: parent,
    children: children
  )
  for child in result.children:
    child.parent = result

proc isRootNode*(self: TreeNode): bool =
  self.isRootNode

proc insert*[T](self: TreeNode[T], value: TreeNode[T], index: int) {.discardable.} =
  if not value.isRootNode:
    value.parent = self
    self.children.insert(value, clamp(index, 0, self.children.len))

proc add*(self: TreeNode, value: TreeNode): TreeNode {.discardable.} =
  let newNode = initTreeNode(value.value, self, value.children)
  self.children.add(newNode)


proc add*[T](self: TreeNode[T], value: T): TreeNode[T] {.discardable.} =
  ## Add values as new nodes to self
  ## return last node to be added
  result = initTreeNode[T](value, self)
  self.children.add(result)

proc add*[T](self: TreeNode[T], values: seq[T]): seq[TreeNode[T]] {.discardable.} =
  ## Add values as new nodes to self
  ## return last node to be added
  result = values.mapIt(self.add(it))

proc drop*(self: TreeNode) =
  if not self.isRootNode:
    let index = self.parent.children.find(self)
    self.parent.children.delete(index)

proc walk*(self: TreeNode, operation: (TreeNode)->bool) =
  if operation self: return
  for child in self.children:
    child.walk operation

template walkIt*[T](self: TreeNode[T], body: untyped) =
  self.walk do (it {.inject.}: TreeNode[T])->bool:
    body

template firstIt*[T](self: TreeNode[T], predicate: untyped): Option[TreeNode[T]] =
  var matchinNode: Option[TreeNode[T]]
  self.walkIt:
    if predicate:
      matchinNode = some it
      return true
  matchinNode

template allIt*[T](self: TreeNode[T], predicate: untyped): seq[TreeNode[T]] =
  var matchinNodes = newSeq[TreeNode[T]]()
  self.walkIt:
    if predicate:
      matchinNodes.add it
  matchinNodes