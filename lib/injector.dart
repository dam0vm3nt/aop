library aop.injector;

import "dart:async";

import "package:analyzer/analyzer.dart";

abstract class MethodMatcher {
  bool matches(MethodDeclaration declaration);
}

class SimpleMethodMatcher implements MethodMatcher {
  Pattern name;

  SimpleMethodMatcher({this.name});

  bool matches(MethodDeclaration declaration) {
    return name.allMatches(declaration.name.toString()).isNotEmpty;
  }
}

class MethodInterceptorPointcut extends RecursiveAstVisitor {
  MethodMatcher matcher;

  MethodInterceptorPointcut({this.matcher});

  visitMethodDeclaration(MethodDeclaration node) {
    print("Method : ${node.name.toString()} : ${node.offset} - ${node.end}");
    if (matcher.matches(node)) {
      // Recurr on body and inject callbacks to Aop
      print("Matches");

    }

  }

}

class Injector {

  List<AstVisitor> interceptors;

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