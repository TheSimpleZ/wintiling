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

proc initTreeNode*[T](nodeVal: T): TreeNode[T] =
  result = TreeNode[T](value: nodeVal, isRootNode: true)


proc initTreeNode[T](nodeVal: T, parent: TreeNode[T]): TreeNode[T] =
  result = TreeNode[T](value: nodeVal, isRootNode: false, parent: parent)

proc isRootNode*(self: TreeNode): bool =
  self.isRootNode

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
      return true
  matchinNodes