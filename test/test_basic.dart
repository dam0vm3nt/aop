import "package:test/test.dart";

import "package:aop/injector.dart";
import "package:resource/resource.dart" as res;
import "package:logging/logging.dart";

class Sample extends Object with AopWrappers {
  void methodXYZ(String a, {ciccio}) {
    $aop$(
        new InvokationContext(
            'pointcut1', 'methodXYZ', [a], {'ciccio': ciccio}), () {
      print(a);
    });
  }

  int methodA(int b, [int x = 10]) {
    return $aop$(new InvokationContext('pointcut1', 'methodA', [b, x], {}), () {
      return b + x;
    });
  }

  methodVarRet(x, b, z) {
    return $aop$(
        new InvokationContext('pointcut1', 'methodVarRet', [x, b, z], {}), () {
      return x + b - z;
    });
  }
}

void main() {
  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.loggerName} - ${rec.message}');
  });

  group("zero", () {
    setUp(() {
      pointcutRegistry.register("pointcut1",
          (InvokationContext ctx, Function proceed) {
        print("BEFORE ${ctx}");
        var res;
        if (ctx.methodName == "methodA") {
          res = -1;
        } else {
          res = proceed();
        }
        print("AFTER : ${res}");
        return res;
      });
    });

    test("notest", () {
      Sample s = new Sample();
      s.methodXYZ("Giulia");
      print(s.methodA(2));
    });
  });

  group("basic", () {
    Injector injector;

    setUp(() {
      injector = new Injector()
        ..interceptors = [
          new MethodInterceptorPointcut()
            ..id = "pointcut1"
            ..matcher = new SimpleMethodMatcher(name: new RegExp(r"^method.*$"))
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
