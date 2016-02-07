library aop;

class Pointcut {
  final String expression;

  const Pointcut(this.expression);
}

class Aspect {
  const Aspect();
}

const Aspect aspect = const Aspect();

class InvokationContext {
  String pointcutId;
  String methodName;
  List positionalParameters;
  Map<String, dynamic> namedParameters;
  InvokationContext(this.pointcutId, this.methodName, this.positionalParameters,
      this.namedParameters);

  String toString() => "PoincutID:$pointcutId, Method:${methodName}";
}

typedef AspectFactory();

class AopContext {

  Map<Type,AspectFactory> _aspectByType= {};

  void registerAspect(Type aspectType,AspectFactory factory) {
    _aspectByType[aspectType] = factory;
  }

  aspect(Type aspectType) => _aspectByType[aspectType]();

  AopContext._();

}

final AopContext aopContext = new AopContext._();

