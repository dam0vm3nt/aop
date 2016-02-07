import "package:aop/aop.dart";

@aspect
class MySampleAspect {
  @Pointcut(const Or(const [
    const And(const [
      const NameMatches(r"^method.*$"),
      const AnnotationMatches("pippo")
    ]),
    const Not(const NameMatches(r"XYZ"))
  ]))
  executeAround(InvokationContext context, Function proceed) {
    print("BEFORE (myAspect)");
    var res = proceed();
    print("AFTER (myAspect)");
    return res;
  }
}
