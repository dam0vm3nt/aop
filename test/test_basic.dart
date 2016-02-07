library aop.test;

import 'package:aop/aop.dart';
import "package:aop/injector.dart";
import "package:aop/analyzer.dart";
import "package:logging/logging.dart";
import "package:resource/resource.dart" as res;
import "package:test/test.dart";
import 'sample_aspect.dart';

part "sample_translated.dart";

class MyAopInitializer {
  void execute() {
    pointcutRegistry.register('MySampleAspect.executeAround',(context,proceed) => aopContext.aspect(MySampleAspect).executeAround(context,proceed) );
    aopContext.registerAspect(MySampleAspect,() => new MySampleAspect());
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
        ..register("logger",(InvokationContext ctx,Function proceed) {
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

      AnalyzerResult newContent = analyzer.analyze(content, u.toString());
      print("factory:\n${newContent.initializer}");

      newContent.pointcutDeclarations[0].createInterceptor();
    });
  });

  group("injector", () {
    Injector injector;

    setUp(() async {
      Analyzer analyzer = new Analyzer();
      Uri u = new Uri.file("test/sample_aspect.dart");
      res.Resource x = new res.Resource(u.toString());

      String content = await x.readAsString();

      AnalyzerResult newContent = analyzer.analyze(content, u.toString());
      print("factory:\n${newContent.initializer}");




      injector = new Injector()
        ..interceptors = [
          new MethodInterceptorPointcut()
            ..id = "logger"
            ..matcher = new SimpleMethodMatcher(name: new RegExp(".*"))
        ];
      injector.interceptors.addAll(newContent.pointcutDeclarations.map((PointcutDeclaration pcdecl) => pcdecl.createInterceptor()));
    });

    test("test1", () async {
      Uri u = new Uri.file("test/sample.dart");
      res.Resource x = new res.Resource(u.toString());

      String content = await x.readAsString();

      String newContent = await injector.inject(content, u.toString());
      print("TRANSORMED:\n${newContent}");
    });
  });
}
