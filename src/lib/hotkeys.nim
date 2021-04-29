import macros
import macroutils
import sets
export sets
import tables
export tables

macro initHotkeys*(mappings: untyped): auto =
  # echo mappings.repr
  result = StmtList(DotExpr(TableConstr(), Ident "toTable"))
  for map in mappings:
    result[0].left.add(
      ExprColonExpr(
        Command(Ident "toHashSet", macroutils.name(map)),
        map.arguments[0][0]
      )
    )
