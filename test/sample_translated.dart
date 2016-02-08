part of aop.test;





class Pippo {
  const Pippo();
}

const Pippo pippo = const Pippo();

class Sample extends Object with AopWrappers {
  void methodXYZ(String a, {ciccio}) { $aop$(new InvokationContext('logger','methodXYZ',[a],{'ciccio':ciccio}),() {
    print(a);
  });}

  @pippo
  int methodA(int b, [int x = 10]) { return $aop$(new InvokationContext('logger','methodA',[b,x],{}),() { return $aop$(new InvokationContext('MySampleAspect.executeAround','methodA',[b,x],{}),() {
    return b + x;
  });});}

  methodVarRet(x, b, z) { return $aop$(new InvokationContext('logger','methodVarRet',[x,b,z],{}),() { return $aop$(new InvokationContext('MySampleAspect.executeAround','methodVarRet',[x,b,z],{}),() {
    return x + b - z;
  });});}

  methodExpr(a,b) => $aop$(new InvokationContext('logger','methodExpr',[a,b],{}),() => $aop$(new InvokationContext('MySampleAspect.executeAround','methodExpr',[a,b],{}),() => a-b));
}
