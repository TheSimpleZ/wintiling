import ../src/tree

import sequtils

block init:
  var fakeTree = initTree(0)
  doAssert fakeTree.rootNode.value == 0, "Can't initialize Tree"

block add:
  var fakeTree = initTree(0)
  fakeTree.add(1)

  let newNode = fakeTree.rootNode.children[0];

  doAssert newNode != nil and newNode.value == 1, "Could not add child node"
  doAssert not newNode.isRootNode, "Child node is also root node"

block drop:
  var fakeTree = initTree(0)
  fakeTree.add(1)

  let child = fakeTree.rootNode.children[0]

  drop child

  doAssert fakeTree.rootNode.children.len == 0, "Could not drop child node"

block walkTree:
  var fakeTree: Tree[int] = initTree 0
  fakeTree.add 1, 2, 3
  fakeTree.rootNode.children[0].add 4
  const expected = @[0, 1, 4, 2, 3]

  var values = newSeq[int]()

  for node in walk fakeTree:
    values.add node.value
  doAssert values == expected, "Could not visit all nodes during walk"

block allchildren:
  var fakeTree = initTree 0
  fakeTree.add 1, 2, 3


  let actual = fakeTree.all do (node: TreeNode[int])->bool:
    node.value > 2

  doAssert actual.allIt(it.value > 2), "Failed to apply `all` predicate"

block first:
  var fakeTree = initTree 0
  fakeTree.add 1, 2, 3, 4

  let actual = fakeTree.first do (node: TreeNode[int])->bool:
    node.value > 2
  doAssert actual.value == 3


# block leafchildren:
#   let fakeTree: Tree[int] = initTree(0, @[
#     initTree(1, @[
#       initTree(3),
#       initTree(5, @[initTree(7), initTree(9)])
#     ]),
#     initTree(2, @[
#       initTree(4),
#       initTree(6, @[initTree(10), initTree(12)]),
#       initTree(8),
#     ]),
#     initTree(33),
#   ])
#   const expectedchildren = [3, 7, 9, 4, 10, 12, 8, 33]
#   for leafNode in fakeTree.leafchildren:
#     doAssert expectedchildren.contains(leafNode.value), "Failed to get all leafchildren"
