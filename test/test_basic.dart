import 'package:aop/aop.dart';
import "package:aop/injector.dart";
import "package:aop/analyzer.dart";
import "package:logging/logging.dart";
import "package:resource/resource.dart" as res;
import "package:test/test.dart";
import 'sample_aspect.dart';

class Sample extends Object with AopWrappers {
  void methodXYZ(String a, {ciccio}) { $aop$(new InvokationContext('MySampleAspect.executeAround','methodXYZ',[a],{'ciccio':ciccio}),() { $aop$(new InvokationContext('logger','methodXYZ',[a],{'ciccio':ciccio}),() {
    print(a);
  });});}

  int methodA(int b, [int x = 10]) { return $aop$(new InvokationContext('MySampleAspect.executeAround','methodA',[b,x],{}),() { return $aop$(new InvokationContext('logger','methodA',[b,x],{}),() {
    return b + x;
  });});}

  methodVarRet(x, b, z) { return $aop$(new InvokationContext('MySampleAspect.executeAround','methodVarRet',[x,b,z],{}),() { return $aop$(new InvokationContext('logger','methodVarRet',[x,b,z],{}),() {
    return x + b - z;
  });});}

  methodExpr(a,b) => $aop$(new InvokationContext('MySampleAspect.executeAround','methodExpr',[a,b],{}),() => $aop$(new InvokationContext('logger','methodExpr',[a,b],{}),() => a-b));
}

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

      String newContent = await analyzer.analyze(content, u.toString());
      print("factory:\n${newContent}");
    });
  });

  group("injector", () {
    Injector injector;

    setUp(() {
      injector = new Injector()
        ..interceptors = [
          new MethodInterceptorPointcut()
            ..id = "MySampleAspect.executeAround"
            ..matcher = new SimpleMethodMatcher(name: new RegExp(r"^method.*$")),
          new MethodInterceptorPointcut()
            ..id = "logger"
            ..matcher = new SimpleMethodMatcher(name: new RegExp(".*"))
        ];
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
