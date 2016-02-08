# TRIVIAL AOP framework for Dart

A very simple AOP framework for Dart.

## Premise

Dart has transformers. They're used for several different purposes but one of the most
common is to inject code. AOP should be a better framework for doing this kind of things. 

## Usage

Declare your aspect anywhere in your code, for example:

    import "package:aop/aop.dart";
    
    @aspect    
    class MySampleAspect {
    
     @Pointcut(const AnnotationMatches("pippo"))
     executeAround(InvocationContext context, Function proceed) {
      print("BEFORE (myAspect)");
      var res = proceed();
      print("AFTER (myAspect)");
      return res;
     }
    }
    
This defines an aspect that will print a message before and after execution of any method in your code that is
annotated with `@pippo`.

An aspect is just a class annotated with `@aspect`.
    
`Pointcut` are defined using the annotation `@Pointcut`. The annotation constructor argument is a const expression
that defines the pointcut.

At the moment the expression is limited to:

 - `NameMatches` to match the method name (using a regexp)
 - `AnnotationMatches` to match an annotation of the method
 - `IsGetter` / `IsSetter` to check if the method is a getter or setter
 - `And`, `Or`, `Not` try to guess ?

Also you can only write `around` pointcut for method.
Using `IsGetter` or `IsSetter` on a property will cause the pointcut to be called for both read and write operation on that property.
The `InvocationContext` will have a `getter` or `setter` property set to `true` to distinguish the one from the other.

For example `aop` can be used to automatically call `set`  method on a `polymer` 1.0 component:

     @aspect
    class AutoSetter {
      @Pointcut(const And(const [const AnnotationMatches("property"), const IsGetter()]))
      callSetter(InvocationContext context, Function proceed) {
        if(context.setter) {
          (context.target as PolymerElement).set(
              context.methodName, context.positionalParameters[0]);
          //context.target.set()
        }
      }
    }
 
## the transformer

To inject pointcut executions a trasformer need to be added to your `pubspec` configuration. The trasformer needs a list of `entry_points` to be configured.
It uses `initialize` so if used with `polymer` there's nothing else to do, otherwise you have to add `initialize` trasformer too.

For example:

    transformers:
     - aop:
        entry_points: web/index.dart
     - polymer:
        entry_points: web/index.html


## entry point

The main entry point needs to call `initialize` `run` method to get the aop framework properly initialized, for example:

    
    main() async {
      await run();

      await initPolymer();
    }

## next step

More expressions (for example class selector, annotation on classes). Aspect lifecycle and scope. Support for property. Support for mixin injection.