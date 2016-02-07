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
  String url;

  PointcutInterceptor createInterceptor() =>
      new MethodInterceptorPointcut()
        ..id = pointcutId
        ..matcher = new ExpressionMethodMatcher(pointcutDefAnnotation.arguments.arguments.first);


  String get pointcutId => "${cdecl.name}.${mdecl.name}";

  PointcutDeclaration({this.url,this.cdecl, this.mdecl, this.pointcutDefAnnotation});

  void buildPointcutRegister(StringBuffer buffer,String prefix) {
    buffer.write(" pointcutRegistry.register('");
    buffer.write(pointcutId);
    buffer.write("',(context,proceed) => aopContext.aspect(${prefix}.${cdecl.name}).${mdecl.name}(context,proceed) );\n");
  }

  void buildDefaultAopRegistry(StringBuffer buffer,String prefix) {
    buffer.write(" aspectRegistry.registerAspect(${prefix}.${cdecl.name},() => new ${prefix}.${cdecl.name}());\n");
  }


}


class PointcutCollector extends RecursiveAstVisitor {

  ClassDeclaration cdecl;
  List<PointcutDeclaration> poincutDeclarations;
  String url;

  PointcutCollector(this.url,this.cdecl, this.poincutDeclarations);

  visitMethodDeclaration(MethodDeclaration mdecl) {
    Iterable<Annotation> pointcutDefs = mdecl.metadata.where((
        Annotation anno) => anno.name.name == "Pointcut");
    pointcutDefs.forEach((Annotation pointcutDefAnnotation) {
      logger.fine("FOUND pointcut : ${mdecl.name.name} , ${pointcutDefAnnotation
          .arguments.arguments[0]}");
      poincutDeclarations.add(new PointcutDeclaration(
          url:url,
          pointcutDefAnnotation: pointcutDefAnnotation,
          cdecl: cdecl,
          mdecl: mdecl
      ));
    });
  }
}

class AspectCollector extends RecursiveAstVisitor {

  List<PointcutDeclaration> poincutDeclarations;
  String url;

  AspectCollector(this.poincutDeclarations,this.url);

  visitClassDeclaration(ClassDeclaration cdecl) {
    if (cdecl.metadata.any((Annotation anno) => anno.name.name == "aspect")) {
      logger.fine("FOUND ASPECT : ${cdecl.name.name} in ${url}");

      cdecl.accept(new PointcutCollector(url,cdecl, poincutDeclarations));
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

class AnalyzerResult {
  List<PointcutDeclaration> pointcutDeclarations;
  String initializer;

  AnalyzerResult(this.pointcutDeclarations,this.initializer);
}

class Analyzer {
  List<PointcutDeclaration> pointcutDeclarations;


  void start() {
    pointcutDeclarations = [];
  }

  void analyze(String contents, String url)  {
    CompilationUnit unit = parseCompilationUnit(contents,parseFunctionBodies: false);

    unit.accept(new AspectCollector(pointcutDeclarations,url));
  }

  AnalyzerResult end() {
    StringBuffer buffer = new StringBuffer();


    buffer.write(
        "import 'package:initialize/initialize.dart';\n"
        "import 'package:aop/aop.dart';\n");
    Map<String,String>  prefixes={};

    pointcutDeclarations.forEach((PointcutDeclaration pd) {
      prefixes.putIfAbsent(pd.url,() {
        String prefix = "pd${prefixes.length}";
        buffer.write("import '${pd.url}' as ${prefix};\n");
        return prefix;
      });

    });


    buffer.write(
        "@initMethod\n"
        "init_aop() {\n");
    pointcutDeclarations.forEach((PointcutDeclaration pdecl) {
      pdecl.buildPointcutRegister(buffer,prefixes[pdecl.url]);
      pdecl.buildDefaultAopRegistry(buffer,prefixes[pdecl.url]);
    });

    buffer.write("}\n");


    return new AnalyzerResult(pointcutDeclarations,buffer.toString());
  }

}