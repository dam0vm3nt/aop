library aop.test;

import "package:aop/src/analyzer.dart";
import 'package:aop/aop.dart';
import "package:aop/src/injector.dart";
import 'package:aop/src/pointcut_registry.dart';
import "package:logging/logging.dart";
import "package:resource/resource.dart" as res;
import "package:test/test.dart";

import 'sample_aspect.dart' as pd0;

part "sample_translated.dart";

class MyAopInitializer {
  void execute() {
    pointcutRegistry.register('MySampleAspect.executeAround',(context,proceed) => aspectRegistry.aspect(pd0.MySampleAspect).executeAround(context,proceed) );
    aspectRegistry.registerAspect(pd0.MySampleAspect,() => new pd0.MySampleAspect());
    pointcutRegistry.register('MySampleAspect.getUno',(context,proceed) => aspectRegistry.aspect(pd0.MySampleAspect).getUno(context,proceed) );
    aspectRegistry.registerAspect(pd0.MySampleAspect,() => new pd0.MySampleAspect());
  }
}

void main() {
  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.loggerName} - ${rec.message}');
  });

  group("zero", () {
    setUp(() {

      new MyAopInitializer().execute();

      pointcutRegistry
        ..register("logger",(InvocationContext ctx,Function proceed) {
          print("LOGGER BEFORE ${ctx}");
          var res=proceed();
          print("LOGGER AFTER ${ctx}");
          return res;
        });
    });

    test("notest", () {
      Sample s = new Sample();
      s.methodXYZ("Giulia");
      print(s.methodA(2));
      s.uno=1;
      print(s.uno);
    });
  });

  group("analyzer", () {
    Analyzer analyzer;

    setUp(() {
      analyzer = new Analyzer();
    });

    test("test1", () async {
      Uri u = new Uri.file("test/sample_aspect.dart");
      res.Resource x = new res.Resource(u.toString());

      String content = await x.readAsString();
      analyzer.start();
      analyzer.analyze(content,u.toString());

      AnalyzerResult newContent = analyzer.end();
      print("factory:\n${newContent.initializer}");

      newContent.pointcutDeclarations[0].createInterceptors();
    });
  });

  group("injector", () {
    Injector injector;

    setUp(() async {
      Analyzer analyzer = new Analyzer();
      Uri u = new Uri.file("test/sample_aspect.dart");
      res.Resource x = new res.Resource(u.toString());

      String content = await x.readAsString();

      analyzer.start();
      analyzer.analyze(content,u.toString());

      AnalyzerResult newContent = analyzer.end();
      print("factory:\n${newContent.initializer}");




      injector = new Injector()
        ..interceptors = [
          new MethodInterceptorPointcut()
            ..id = "logger"
            ..matcher = new SimpleMethodMatcher(name: new RegExp(".*"))
        ];
      injector.interceptors.addAll(newContent.pointcutDeclarations.fold([],(List b,PointcutDeclaration pcdecl) => b..addAll(pcdecl.createInterceptors())));
    });

    test("test1", () async {
      Uri u = new Uri.file("test/sample.dart");
      res.Resource x = new res.Resource(u.toString());

      String content = await x.readAsString();

      String newContent = injector.inject(content, u.toString(),true);
      print("TRANSORMED:\n${newContent}");
    });
  });
}
