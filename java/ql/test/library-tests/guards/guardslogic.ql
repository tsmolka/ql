import java
import semmle.code.java.controlflow.Guards

from Guard g, BasicBlock bb, boolean branch
where g.controls(bb, branch)
and not g instanceof ParExpr
and g.getEnclosingCallable().getDeclaringType().hasName("Logic")
select g, branch, bb
