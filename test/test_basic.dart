import "package:test/test.dart";

import "package:aop/injector.dart";

void main() {
  group("basic", () {
    Injector injector;

    setUp(() {
      injector = new Injector()
        ..interceptors = [
          new MethodInterceptorPointcut()
            ..matcher = new SimpleMethodMatcher(name: new RegExp(r"^method.*$"))
        ];
    });

    test("test1", () {
      injector.inject("""

      class Sample {
         void methodXY(String a,{int y,int z}) {
          print("Ciao");
        }
      }


      """);
    });
  });
}
