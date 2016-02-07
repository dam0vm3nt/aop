import "package:aop/aop.dart";

typedef PointcutHandler(InvokationContext ctx, Function proceed);

class PointcutRegistry {
  Map<String, PointcutHandler> _handlersById = {};

  executePointcuts(InvokationContext ctx, Function closure) {
    // TODO : replace with a list of pointcutsID

    PointcutHandler handler = _handlersById[ctx.pointcutId];
    if (handler == null) {
      //logger.warning("Pointcut ${ctx.pointcutId}, NOT REGISTERED!!!");
      return closure();
    }

    return handler(ctx, closure);
  }

  void register(String pointcutId, PointcutHandler handler) {
    _handlersById[pointcutId] = handler;
  }

  PointcutRegistry._();
}

final PointcutRegistry pointcutRegistry = new PointcutRegistry._();


