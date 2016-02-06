library aop.injector;

import "dart:async";

import "package:analyzer/analyzer.dart";

abstract class MethodMatcher {
  bool matches();
}

class MethodInterceptorPointcut extends RecursiveAstVisitor {
  MethodMatcher matcher;



}

class Injector {

  List<AstVisitor> interceptors = [
  ];

  /**
   * Take a file, analyze it, check the pointcuts and then inject the behavior.
   */
  Future<String> inject(String contents) async {
    CompilationUnit unit = parseCompilationUnit(contents);

    interceptors.forEach((AstVisitor interceptor) {
      unit.accept(interceptor);
    });


    return null;
  }
}