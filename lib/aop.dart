library aop;


class MatchExpression {
  const MatchExpression();
}

class NameMatches extends MatchExpression {
  final String pattern;

  const NameMatches(this.pattern);

}

class AnnotationMatches extends MatchExpression {
  final Pattern pattern;
  const AnnotationMatches(this.pattern);
}

class And extends MatchExpression {
  final List<MatchExpression> matchers;

  const And(this.matchers);
}

class Or extends MatchExpression {
  final List<MatchExpression> matchers;

  const Or(this.matchers);
}

class Not extends MatchExpression {
  final MatchExpression expression;

  const Not(this.expression);
}



class Pointcut {
  final dynamic expression;

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

class AspectRegistry {

  Map<Type,AspectFactory> _aspectByType= {};

  void registerAspect(Type aspectType,AspectFactory factory) {
    _aspectByType[aspectType] = factory;
  }

  aspect(Type aspectType) => _aspectByType[aspectType]();

  AspectRegistry._();

}

final AspectRegistry aspectRegistry = new AspectRegistry._();
