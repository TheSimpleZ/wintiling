import questionable

type o = object
  a: int

proc printVal(val: int) =
  echo val

proc doSomething*[T](unused: T) =
  if x =? some(o(a: 1)):
    mixin x
    printVal x.a

doSomething(1)