library aop.injector;

import "dart:async";

import "package:analyzer/analyzer.dart";
import "package:aop/aop.dart";
import "package:aop/src/pointcut_registry.dart";
import "package:logging/logging.dart";
import "package:source_maps/source_maps.dart";
import "package:source_span/source_span.dart";

Logger logger = new Logger("aop.injector");

/**
 * TODO:
 * getters and setters / properties
 * async / async* ecc.
 * better mixin injection
 * better class absolute reference  (with package , with library, ecc.)
 */

abstract class MethodMatcher {
  bool matches(MethodDeclaration declaration);
}

class SimpleMethodMatcher implements MethodMatcher {
  Pattern name;

  SimpleMethodMatcher({this.name});

  bool matches(MethodDeclaration declaration) {
    return name
        .allMatches(declaration.name.toString())
        .isNotEmpty;
  }
}

class ExpressionMatcherVisitor extends GeneralizingAstVisitor<bool> {
  MethodDeclaration mdecl;

  ExpressionMatcherVisitor(this.mdecl);

  bool visitNode(AstNode node) {
    logger.fine("VISITING ${node.runtimeType}");
    return super.visitNode(node);
  }

  bool visitInstanceCreationExpression(InstanceCreationExpression expr) {
    if (!expr.isConst) throw "${expr} is not a constant expression";

    String name = expr.constructorName.toString();

    logger.fine("Looking for a evaluator for ${name}");

    Function e = {
      (NameMatches).toString(): () =>
          evaluateRegExp(expr.argumentList.arguments.first),
      (AnnotationMatches).toString(): () =>
          matchAnnnotation(expr.argumentList.arguments.first),
      (And).toString(): () =>
          matchAnd(asList(expr.argumentList.arguments.first)),
      (Or).toString(): () =>
          matchOr(asList(expr.argumentList.arguments.first)),
      (Not).toString(): () =>
          matchNot(expr.argumentList.arguments.first)
    }[name];

    if (e != null) {
      return e();
    }

    logger.fine("Don't know how to evaluate ${name}");

    return false;
  }

  asList(ListLiteral lit) => lit.elements;

  bool matchNot(Expression expr) =>
      !expr.accept(new ExpressionMatcherVisitor(mdecl));

  bool matchAnd(NodeList args) {
    return args
        .every((AstNode n) => n.accept(new ExpressionMatcherVisitor(mdecl)));
  }

  bool matchOr(NodeList args) {
    return args
        .any((AstNode n) => n.accept(new ExpressionMatcherVisitor(mdecl)));
  }

  bool matchAnnnotation(Expression expr) {
    if (expr is StringLiteral) {
      String val = expr.stringValue;
      logger.fine("Eval ExPR : ${val}");
      RegExp re = new RegExp(val);
      return mdecl.metadata.any((Annotation a) => re.hasMatch(a.name.name));
    }
    return false;
  }

  bool evaluateRegExp(Expression expr) {
    if (expr is StringLiteral) {
      String val = expr.stringValue;
      logger.fine("Eval ExPR : ${val}");
      return new RegExp(val).hasMatch(mdecl.name.name);
    }
    return false;
  }
}

class ExpressionMethodMatcher implements MethodMatcher {
  Expression expression;

  ExpressionMethodMatcher(this.expression);

  bool matches(MethodDeclaration declaration) {
    return expression.accept(new ExpressionMatcherVisitor(declaration));
  }
}

abstract class PointcutInterceptor implements AstVisitor {
  TextEditTransaction edit;
}

class MethodBodyInjector extends RecursiveAstVisitor {
  TextEditTransaction edit;
  MethodDeclaration decl;
  String newInvokationContextText;

  MethodBodyInjector(this.newInvokationContextText, this.decl, this.edit);

  visitBlockFunctionBody(BlockFunctionBody node) {
    logger.fine(
        "Body : \n${node.toSource()}, returns : ${decl.returnType?.name}");
    if (decl.returnType?.name?.name == "void") {
      edit.edit(node.end, node.end, ");}");
      edit.edit(node.offset, node.offset,
          "{ ${AopWrappers
              .AOP_WRAPPER_METHOD_NAME}($newInvokationContextText,() ");
    } else {
      edit.edit(node.end, node.end, ");}");
      edit.edit(node.offset, node.offset,
          "{ return ${AopWrappers
              .AOP_WRAPPER_METHOD_NAME}($newInvokationContextText,() ");
    }
  }

  visitExpressionFunctionBody(ExpressionFunctionBody node) {
    logger.fine(
        "Body : \n${node.toSource()}, returns : ${decl.returnType?.name}");

    edit.edit(node.semicolon.offset, node.semicolon.offset, ")");
    edit.edit(node.offset, node.offset,
        "=> ${AopWrappers
            .AOP_WRAPPER_METHOD_NAME}($newInvokationContextText,() ");
  }
}

class AopMixinInjector extends RecursiveAstVisitor {
  List<PointcutInterceptor> interceptors;
  TextEditTransaction edit;

  AopMixinInjector(this.interceptors, this.edit);

  visitClassDeclaration(ClassDeclaration classDecl) {
    interceptors.forEach((PointcutInterceptor interceptor) {
      interceptor.edit = edit;
      classDecl.accept(interceptor);
    });

    if (edit.hasEdits) {

      if (classDecl.extendsClause==null) {
        edit.edit(classDecl.name.end,classDecl.name.end," extends AopWrappers ");
      } else {
        if (classDecl.withClause==null) {
          edit.edit(classDecl.extendsClause.end,classDecl.extendsClause.end," with AopWrappers ");
        }  else {
          edit.edit(classDecl.withClause.withKeyword.end,classDecl.withClause.withKeyword.end," AopWrappers,");
        }
      }

    }
  }
}

class MethodInterceptorPointcut extends PointcutInterceptor
    with RecursiveAstVisitor {
  String id;

  MethodMatcher matcher;

  MethodInterceptorPointcut({this.id, this.matcher});

  visitMethodDeclaration(MethodDeclaration node) {
    logger.fine(
        "Method : ${node.name.toString()} : ${node.offset} - ${node.end}");
    if (matcher.matches(node)) {
      // Recurr on body and inject callbacks to Aop
      String newInvokationContextText =
      _createInvokationContextInitializerCode(node);
      node.accept(new MethodBodyInjector(newInvokationContextText, node, edit));
    }
  }

  String _createInvokationContextInitializerCode(MethodDeclaration node) {
    StringBuffer sb =
    new StringBuffer("new InvokationContext('$id','${node.name}',[");
    String sep = "";
    node.parameters.parameters
        .where((FormalParameter fp) => fp.kind != ParameterKind.NAMED)
        .forEach((FormalParameter fp) {
      sb.write(sep);
      sb.write(fp.identifier.name);
      sep = ",";
    });
    sb.write("],{");
    sep = "";
    node.parameters.parameters
        .where((FormalParameter fp) => fp.kind == ParameterKind.NAMED)
        .forEach((FormalParameter fp) {
      sb.write(sep);
      sb.write("'${fp.identifier.name}':${fp.identifier.name}");
      sep = ",";
    });
    sb.write("})");
    return sb.toString();
  }
}

class Injector {
  List<PointcutInterceptor> interceptors;

  /**
   * Take a file, analyze it, check the pointcuts and then inject the behavior.
   */
  String inject(String contents, String url, bool isEntryPoint) {
    CompilationUnit unit = parseCompilationUnit(contents);
    SourceFile source = new SourceFile(contents, url: url);
    TextEditTransaction edit = new TextEditTransaction(contents, source);

    unit.accept(new AopMixinInjector(interceptors, edit));

    LibraryDirective lib = unit.directives.firstWhere((Directive d) => d is LibraryDirective,orElse: () => null);
    int pos =0;
    if (lib!=null) {
      pos = lib.end;
    }

    if (edit.hasEdits) {
      edit.edit(pos,pos,"\nimport 'package:aop/src/pointcut_registry.dart' show AopWrappers;\n"
          "import 'package:aop/aop.dart' show InvokationContext;\n");
    }

    if (isEntryPoint) {
      edit.edit(pos,pos,
          "\nimport 'aop_initializer.dart';");
    }

    if (edit.hasEdits) {
      NestedPrinter p = edit.commit();
      p.build(url);
      return p.text;
    }

    return null;
  }
}
