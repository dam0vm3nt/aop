library aop.injector;

import "package:analyzer/analyzer.dart";
import "package:analyzer/src/generated/scanner.dart";
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

abstract class FieldMatcher {
  bool matches(FieldDeclaration declaration);
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

    String name = expr.constructorName
        .toString(); // becuase name if null => default then take class, better toString...

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
          matchNot(expr.argumentList.arguments.first),
      (IsGetter).toString(): () =>
      mdecl.isGetter,
      (IsSetter).toString(): () => mdecl.isSetter
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


class ExpressionFieldMatcherVisitor extends GeneralizingAstVisitor<bool> {
  FieldDeclaration fdecl;

  ExpressionFieldMatcherVisitor(this.fdecl);

  bool visitNode(AstNode node) {
    logger.fine("VISITING ${node.runtimeType}");
    return super.visitNode(node);
  }

  bool visitInstanceCreationExpression(InstanceCreationExpression expr) {
    if (!expr.isConst) throw "${expr} is not a constant expression";

    String name = expr.constructorName
        .toString(); // becuase name if null => default then take class, better toString...

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
          matchNot(expr.argumentList.arguments.first),
      (IsGetter).toString(): () => true,
      (IsSetter).toString(): () => true
    }[name];

    if (e != null) {
      return e();
    }

    logger.fine("Don't know how to evaluate ${name}");

    return false;
  }

  asList(ListLiteral lit) => lit.elements;

  bool matchNot(Expression expr) =>
      !expr.accept(new ExpressionFieldMatcherVisitor(fdecl));

  bool matchAnd(NodeList args) {
    return args
        .every((AstNode n) =>
        n.accept(new ExpressionFieldMatcherVisitor(fdecl)));
  }

  bool matchOr(NodeList args) {
    return args
        .any((AstNode n) => n.accept(new ExpressionFieldMatcherVisitor(fdecl)));
  }

  bool matchAnnnotation(Expression expr) {
    if (expr is StringLiteral) {
      String val = expr.stringValue;
      logger.fine("Eval ExPR : ${val}");
      RegExp re = new RegExp(val);
      return fdecl.metadata.any((Annotation a) => re.hasMatch(a.name.name));
    }
    return false;
  }

  bool evaluateRegExp(Expression expr) {
    if (expr is StringLiteral) {
      String val = expr.stringValue;
      logger.fine("Eval ExPR : ${val}");
      RegExp re = new RegExp(val);
      return fdecl.fields.variables.any((VariableDeclaration vd) =>
          re.hasMatch(vd.name.name));
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


class ExpressionFieldMatcher implements FieldMatcher {
  Expression expression;

  ExpressionFieldMatcher(this.expression);

  bool matches(FieldDeclaration declaration) {
    return expression.accept(new ExpressionFieldMatcherVisitor(declaration));
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
      if (classDecl.extendsClause == null) {
        edit.edit(
            classDecl.name.end, classDecl.name.end, " extends AopWrappers ");
      } else {
        if (classDecl.withClause == null) {
          edit.edit(classDecl.extendsClause.end, classDecl.extendsClause.end,
              " with AopWrappers ");
        } else {
          edit.edit(classDecl.withClause.withKeyword.end,
              classDecl.withClause.withKeyword.end, " AopWrappers,");
        }
      }
    }
  }
}

class GetterSetterInterceptorPointcut extends PointcutInterceptor
    with RecursiveAstVisitor {
  String id;
  FieldMatcher matcher;
  ClassDeclaration cdecl;

  GetterSetterInterceptorPointcut({this.id, this.matcher});

  visitClassDeclaration(ClassDeclaration cdecl) {
    this.cdecl = cdecl;
    cdecl.visitChildren(this);
  }

  visitFieldDeclaration(FieldDeclaration fdecl) {
    if (!matcher.matches(fdecl)) {
      return;
    }

    // Convert prop to getter / setter
    _transformFields(fdecl, edit);
  }


  /**
   * <WARNING> : THE FOLLOWING STUFF IS RUBBED FROM package `observe`.
   * All credits to the authors.
   *
   */

  void _transformFields(FieldDeclaration member,
      TextEditTransaction code /*, BuildLogger logger*/) {
    final fields = member.fields;

    // Unfortunately "var" doesn't work in all positions where type annotations
    // are allowed, such as "var get name". So we use "dynamic" instead.
    var type = 'dynamic';
    if (fields.type != null) {
      type = _getOriginalCode(code, fields.type);
    } else if (_hasKeyword(fields.keyword, Keyword.VAR)) {
      // Replace 'var' with 'dynamic'
      code.edit(fields.keyword.offset, fields.keyword.end, type);
    }

    // Note: the replacements here are a bit subtle. It needs to support multiple
    // fields declared via the same @observable, as well as preserving newlines.
    // (Preserving newlines is important because it allows the generated code to
    // be debugged without needing a source map.)
    //
    // For example:
    //
    //     @observable
    //     @otherMetaData
    //         Foo
    //             foo = 1, bar = 2,
    //             baz;
    //
    // Will be transformed into something like:
    //
    //     @reflectable @observable
    //     @OtherMetaData()
    //         Foo
    //             get foo => __foo; Foo __foo = 1; @reflectable set foo ...; ...
    //             @observable @OtherMetaData() Foo get baz => __baz; Foo baz; ...
    //
    // Metadata is moved to the getter.

    String metadata = '';
    if (fields.variables.length > 0) {
      // always collect metadata because reflectable wants it on setter too
      metadata =
          member.metadata.map((m) => _getOriginalCode(code, m)).join(' ');
      metadata =
      '$metadata'; // TODO(dam0vment) put polymer @reflectable here  ?
    }

    for (int i = 0; i < fields.variables.length; i++) {
      final field = fields.variables[i];
      final name = field.name.name;

      var beforeInit = 'get $name => ${AopWrappers
          .AOP_WRAPPER_METHOD_NAME}(new InvocationContext("${id}",this,"$name",[],{},getter:true), () => __\$$name); $type __\$$name';

      // The first field is expanded differently from subsequent fields, because
      // we can reuse the metadata and type annotation.
      if (i == 0) {
        //final begin = member.metadata.first.offset;
        //code.edit(begin, begin, '@reflectable '); // TODO(dam0vm3nt) restore polymer reflectable here ?
      } else {
        beforeInit = '$metadata $type $beforeInit';
      }

      code.edit(field.name.offset, field.name.end, beforeInit);

      // Replace comma with semicolon
      final end = _findFieldSeperator(field.endToken.next);
      if (end.type == TokenType.COMMA) code.edit(end.offset, end.end, ';');

      code.edit(end.end, end.end,
          ' $metadata  set $name($type value) { ' // TODO(dam0vm3nt) restore polymer reflectable here ?
              '${AopWrappers
              .AOP_WRAPPER_METHOD_NAME}(new InvocationContext("${id}",this,"$name",[value],{},setter:true), () => __\$$name = value); }');
    }
  }


  String _getOriginalCode(TextEditTransaction code, AstNode node) =>
      code.original.substring(node.offset, node.end);


  Token _findFieldSeperator(Token token) {
    while (token != null) {
      if (token.type == TokenType.COMMA || token.type == TokenType.SEMICOLON) {
        break;
      }
      token = token.next;
    }
    return token;
  }

  bool _hasKeyword(Token token, Keyword keyword) =>
      token is KeywordToken && token.keyword == keyword;

/**
 * </WARNING>
 */


}

class MethodInterceptorPointcut extends PointcutInterceptor
    with RecursiveAstVisitor {
  String id;

  MethodMatcher matcher;

  MethodInterceptorPointcut({this.id, this.matcher});

  visitFieldDeclaration(FieldDeclaration node) {
    // Should be treated like if it's a getter / setter


  }

  visitMethodDeclaration(MethodDeclaration node) {
    logger.fine(
        "Method : ${node.name.toString()} : ${node.offset} - ${node.end}");
    if (matcher.matches(node)) {
      // Recurr on body and inject callbacks to Aop
      String newInvocationContextText =
      _createInvocationContextInitializerCode(node);
      node.accept(new MethodBodyInjector(newInvocationContextText, node, edit));
    }
  }

  String _createInvocationContextInitializerCode(MethodDeclaration node) {
    StringBuffer sb =
    new StringBuffer("new InvocationContext('$id',this,'${node.name}',[");
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

    LibraryDirective lib = unit.directives.firstWhere((
        Directive d) => d is LibraryDirective, orElse: () => null);
    int pos = 0;
    if (lib != null) {
      pos = lib.end;
    }

    if (edit.hasEdits) {
      edit.edit(pos, pos,
          "\nimport 'package:aop/src/pointcut_registry.dart' show AopWrappers;\n"
              "import 'package:aop/aop.dart' show InvocationContext;\n");
    }

    if (isEntryPoint) {
      edit.edit(pos, pos,
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
