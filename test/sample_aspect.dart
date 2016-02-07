
import "package:aop/aop.dart";

@aspect
class MySampleAspect {

  @Pointcut(const AndMatcher(
      const [
        const NameMatcher(r"^method.*$"),
        const AnnotationMatcher("pippo")
      ]))
  executeAround(InvokationContext context,Function proceed) {
    print("BEFORE (myAspect)");
    var res = proceed();
    print("AFTER (myAspect)");
    return res;
  }
}