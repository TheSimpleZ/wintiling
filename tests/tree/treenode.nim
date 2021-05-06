import ../src/treenode
import sugar
import sequtils

block init:
  var fakeTree = newTreeNode(0)
  doAssert fakeTree.value == 0, "Can't initialize Tree"

block add:
  var fakeTree = newTreeNode(0)
  fakeTree.add(1)

  let newNode = fakeTree.add(1)

  doAssert newNode != nil and newNode.value == 1, "Could not add child node"
  doAssert not newNode.isRootNode, "Child node is also root node"

block drop:
  var fakeTree = newTreeNode(0)
  fakeTree.add(1)

  let child = fakeTree.children[0]

  drop child

  doAssert fakeTree.children.len == 0, "Could not drop child node"

block walkTree:
  var fakeTree = newTreeNode 0
  fakeTree.add @[1, 2, 3]
  fakeTree.children[0].add 4
  const expected = @[0, 1, 4, 2, 3]

  var values = newSeq[int]()

  fakeTree.walkIt:
    echo it.value
    values.add it.value
  doAssert values == expected, "Could not visit all nodes during walk"
