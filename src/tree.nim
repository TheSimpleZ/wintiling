import winim/com
import sequtils
import sugar
import options
import macros


macro toItr*(x: ForLoopStmt): untyped =
  let expr = x[0]
  let call = x[1][1] # Get foo out of toItr(foo)
  let body = x[2]
  result = quote do:
    block:
      let itr = `call`
      for `expr` in itr():
          `body`

type
  TreeNode*[T] = ref object of RootObj
    value*: T
    children*: seq[TreeNode[T]]
    parent*: TreeNode[T]

  Tree*[T] = object of RootObj
    rootNode*: TreeNode[T]

  Walkable[T] = Tree[T] or TreeNode[T]

proc initTree*[T](nodeVal: T): Tree[T] =
  result.rootNode = TreeNode[T](value: nodeVal)

proc isRootNode*(self: TreeNode): bool =
  self.parent == nil

proc children*[T](self: Tree): seq[TreeNode[T]] =
  self.rootNode.children

proc add*(self: TreeNode, values: varargs[TreeNode.T]): seq[TreeNode] {.discardable.} =
  ## Add values as new nodes to self
  ## return last node to be added
  result = values.mapIt(TreeNode(value: it, parent: self))
  self.children.add(result)

proc add*[T](self: Tree[T], values: varargs[T]): seq[TreeNode[T]] {.discardable.} =
  self.rootNode.add(values)


proc drop*(self: TreeNode) =
  if not self.isRootNode:
    let index = self.parent.children.find(self)
    self.parent.children.delete(index)

proc walk*[T](self: Walkable[T]): iterator (): TreeNode[T] =
  ## Iterate over each node under and including self
  result = iterator (): TreeNode[T] =
    yield TreeNode(self)
    for child in self.children:
      yield walk(child)()

# proc walkRec*(self: TreeNode, operation: (TreeNode)->bool) =
#   for node in self.children:
#     if operation node: return
#     walkRec node, operation

# proc walk*(self: TreeNode, operation: (TreeNode)->bool) =
#   ## Run `operation` on each node
#   ## Stop when returning `true`
#   if operation(self): return
#   walkRec(self, operation)

# proc walk*[T](self: Tree[T], operation: (TreeNode[T])->bool) =
#   walk self.rootNode, operation


# proc all*[T](self: Tree[T], predicate: (TreeNode[T])->bool): seq[TreeNode[T]] =
#   var children = newSeq[TreeNode[T]]()
#   self.walk do (node: TreeNode[T])->bool:
#     if predicate node:
#       children.add children
#   return children

# proc first*[T](self: Tree[T], predicate: (TreeNode[T])->bool): TreeNode[T] =
#   var matchingNode: TreeNode[T]
#   self.walk do (node: TreeNode[T])->bool:
#     if predicate node:
#       matchingNode = node
#       return true
#   return matchingNode

# proc leafchildren*[T](self: Tree[T]): seq[TreeNode[T]] =
#   self.all do (node: TreeNode[T]) -> bool:
#     node.children.len == 0
