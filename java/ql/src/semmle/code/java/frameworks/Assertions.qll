/**
 * A library providing uniform access to various assertion frameworks.
 *
 * Currently supports `org.junit.Assert`, `junit.framework.*`,
 * `com.google.common.base.Preconditions`, and `java.util.Objects`.
 */

import java

newtype AssertKind =
  AssertKindTrue() or
  AssertKindFalse() or
  AssertKindNotNull() or
  AssertKindFail()

private predicate assertionMethod(Method m, AssertKind kind) {
  exists(RefType junit |
    m.getDeclaringType() = junit and
    (junit.hasQualifiedName("org.junit", "Assert") or junit.hasQualifiedName("junit.framework", _))
    |
    m.hasName("assertNotNull") and kind = AssertKindNotNull() or
    m.hasName("assertTrue") and kind = AssertKindTrue() or
    m.hasName("assertFalse") and kind = AssertKindFalse() or
    m.hasName("fail") and kind = AssertKindFail()
  ) or
  exists(RefType objects |
    m.getDeclaringType() = objects and
    objects.hasQualifiedName("java.util", "Objects")
    |
    m.hasName("requireNonNull") and kind = AssertKindNotNull()
  ) or
  exists(RefType preconditions |
    m.getDeclaringType() = preconditions and
    preconditions.hasQualifiedName("com.google.common.base", "Preconditions")
    |
    m.hasName("checkNotNull") and kind = AssertKindNotNull() or
    m.hasName("checkArgument") and kind = AssertKindTrue() or
    m.hasName("checkState") and kind = AssertKindTrue()
  )
}

class AssertionMethod extends Method {
  AssertionMethod() {
    assertionMethod(this, _)
  }

  /** Gets a call to the assertion method. */
  MethodAccess getACheck() {
    result.getMethod().getSourceDeclaration() = this
  }

  /** Gets a call to the assertion method with `checkedArg` as argument. */
  MethodAccess getACheck(Expr checkedArg) {
    result = getACheck() and checkedArg = result.getAnArgument()
  }
}

/**
 * A method that asserts that its argument is true.
 */
class AssertTrueMethod extends AssertionMethod {
  AssertTrueMethod() {
    assertionMethod(this, AssertKindTrue())
  }
}

/**
 * A method that asserts that its argument is false.
 */
class AssertFalseMethod extends AssertionMethod {
  AssertFalseMethod() {
    assertionMethod(this, AssertKindFalse())
  }
}

/**
 * A method that asserts that its argument is not null.
 */
class AssertNotNullMethod extends AssertionMethod {
  AssertNotNullMethod() {
    assertionMethod(this, AssertKindNotNull())
  }
}

/**
 * A method that unconditionally fails.
 */
class AssertFailMethod extends AssertionMethod {
  AssertFailMethod() {
    assertionMethod(this, AssertKindFail())
  }
}

/** A trivially failing assertion. That is, `assert false` or its equivalents. */
predicate assertFail(BasicBlock bb, ControlFlowNode n) {
  bb = n.getBasicBlock() and
  (
    exists(AssertTrueMethod m | n = m.getACheck(any(BooleanLiteral b | b.getBooleanValue() = false))) or
    exists(AssertFalseMethod m | n = m.getACheck(any(BooleanLiteral b | b.getBooleanValue() = true))) or
    exists(AssertFailMethod m | n = m.getACheck()) or
    n.(AssertStmt).getExpr().getProperExpr().(BooleanLiteral).getBooleanValue() = false
  )
}
