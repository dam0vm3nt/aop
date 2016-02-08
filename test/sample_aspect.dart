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
  executeAround(InvocationContext context, Function proceed) {
    print("BEFORE (myAspect)");
    var res = proceed();
    print("AFTER (myAspect)");
    return res;
  }

  @Pointcut(const And(const [const AnnotationMatches("pippo"),const IsGetter()]))
  void getUno(InvocationContext context,Function proceed) {
    if (context.getter) {
      print("GETTING UNO FROM : ${context.target}");
    }
    if (context.setter) {
      print("SETTING UNO : ${context.positionalParameters[0]}");
    }
  }
}
