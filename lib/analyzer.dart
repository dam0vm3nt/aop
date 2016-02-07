library aop.analyzer;

import "dart:async";

import "package:analyzer/analyzer.dart";
import "package:aop/injector.dart";
import "package:logging/logging.dart";
import "package:source_span/source_span.dart";

Logger logger = new Logger("aop.injector");


class PointcutDeclaration {
  ClassDeclaration cdecl;
  MethodDeclaration mdecl;
  Annotation pointcutDefAnnotation;

  PointcutInterceptor createInterceptor() =>
      new MethodInterceptorPointcut()
        ..id = pointcutId
        ..matcher = new SimpleMethodMatcher(name: new RegExp(
            pointcutDefAnnotation.arguments.arguments.first.toString()));


  String get pointcutId => "${cdecl.name}.${mdecl.name}";

  PointcutDeclaration({this.cdecl, this.mdecl, this.pointcutDefAnnotation});

  void buildPointcutRegister(StringBuffer buffer) {
    buffer.write("pointcutRegistry.register('");
    buffer.write(pointcutId);
    buffer.write("',(context,proceed) => aopContext.aspect(${cdecl.name}).${mdecl.name}(context,proceed) );\n");
  }

  void buildDefaultAopRegistry(StringBuffer buffer) {
    buffer.write("aopContext.registerAspect(${cdecl.name},() => new ${cdecl.name}());\n");
  }


}


class PointcutCollector extends RecursiveAstVisitor {

  ClassDeclaration cdecl;
  List<PointcutDeclaration> poincutDeclarations;

  PointcutCollector(this.cdecl, this.poincutDeclarations);

  visitMethodDeclaration(MethodDeclaration mdecl) {
    Iterable<Annotation> pointcutDefs = mdecl.metadata.where((
        Annotation anno) => anno.name.name == "Pointcut");
    pointcutDefs.forEach((Annotation pointcutDefAnnotation) {
      print("FOUND pointcut : ${mdecl.name.name} , ${pointcutDefAnnotation
          .arguments.arguments[0]}");
      poincutDeclarations.add(new PointcutDeclaration(
          pointcutDefAnnotation: pointcutDefAnnotation,
          cdecl: cdecl,
          mdecl: mdecl
      ));
    });
  }
}

class AspectCollector extends RecursiveAstVisitor {

  List<PointcutDeclaration> poincutDeclarations;

  AspectCollector(this.poincutDeclarations);

  visitClassDeclaration(ClassDeclaration cdecl) {
    if (cdecl.metadata.any((Annotation anno) => anno.name.name == "aspect")) {
      print("FOUND ASPECT : ${cdecl.name.name}");

      cdecl.accept(new PointcutCollector(cdecl, poincutDeclarations));
    }
  }

}

/**
 * Appunti:
 *
 * 2 transformer.
 * Il primo analyzer colleziona i pointcut e produce due cose:
 *  1 - la classe inizializer che inizializza il runtime. Occorre avere due modi di registrare l'aspect.
 *    quello di sistema e quello utente. quello di sistema non sovrascrive se c'è già (ossia se l'utente lo sostituisce).
 *    quello utente invece sovrascrive. In questo modo l'utente avrà sempre il sopravvento indipendentemente dall'ordine
 *    di esecuzione dell'inizializer e del codice utente. Allo stesso modo se non occorre inizializzare viene
 *    comunque fornito un default
 *
 *  2 - l'elenco dei pointcut interceptors che viene memorizzato in memoria e passato al secondo transformer
 *
 * il secondo è l'injector che rimpiazza i metodi ed aggiunge il mixin.
 *
 * Alla fine a runtime : l'initializer inizializza il context ed il pointcut registry. L'utente può sovrascrivere gli
 * aspect se vuole crearli a piacere.
 * Durante l'esecuzione dei metodi alterati viene eseguito il pointcut sull'istanza selezionata.
 */

class Analyzer {

  Future<String> analyze(String contents, String url) async {
    CompilationUnit unit = parseCompilationUnit(contents);
    SourceFile source = new SourceFile(contents, url: url);

    List<PointcutDeclaration> pointcutDeclarations = [];
    unit.accept(new AspectCollector(pointcutDeclarations));


    StringBuffer buffer = new StringBuffer();

    buffer.write("@initializer\n"
        "class MyAopInitializer {\n"
        " void execute() {\n");
    pointcutDeclarations.forEach((PointcutDeclaration pdecl) {
      pdecl.buildPointcutRegister(buffer);
      pdecl.buildDefaultAopRegistry(buffer);
    });

    buffer.write("}\n"
        "}\n");


    return buffer.toString();
  }

}