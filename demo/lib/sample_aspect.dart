import "package:aop/aop.dart";
import "package:polymer/polymer.dart";

@aspect
class MySampleAspect {
  @Pointcut(const AnnotationMatches("pippo"))
  executeAround(InvocationContext context, Function proceed) {
    print("BEFORE (myAspect)");
    var res = proceed();
    print("AFTER (myAspect)");
    return res;
  }
}


@aspect
class AutoSetter {
  @Pointcut(const And(const [const AnnotationMatches("property"), const IsGetter()]))
  callSetter(InvocationContext context, Function proceed) {
    if(context.setter) {
      (context.target as PolymerElement).set(
          context.methodName, context.positionalParameters[0]);
      //context.target.set()
    }
  }
}