
import "package:aop/aop.dart";

@aspect
class MySampleAspect {

  @Pointcut(r"^.*$")
  executeAround(InvokationContext context,Function proceed) {
    print("BEFORE (myAspect)");
    var res = proceed();
    print("AFTER (myAspect)");
    return res;
  }
}