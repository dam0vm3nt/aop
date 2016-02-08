part of aop.test;



class Pippo {
  const Pippo();
}

const Pippo pippo = const Pippo();

class Sample extends AopWrappers  {
  void methodXYZ(String a, {ciccio}) { $aop$(new InvocationContext('logger',this,'methodXYZ',[a],{'ciccio':ciccio}),() {
    print(a);
  });}

  @pippo
  int methodA(int b, [int x = 10]) { return $aop$(new InvocationContext('logger',this,'methodA',[b,x],{}),() { return $aop$(new InvocationContext('MySampleAspect.executeAround',this,'methodA',[b,x],{}),() {
    return b + x;
  });});}

  methodVarRet(x, b, z) { return $aop$(new InvocationContext('logger',this,'methodVarRet',[x,b,z],{}),() { return $aop$(new InvocationContext('MySampleAspect.executeAround',this,'methodVarRet',[x,b,z],{}),() {
    return x + b - z;
  });});}

  methodExpr(a,b) => $aop$(new InvocationContext('logger',this,'methodExpr',[a,b],{}),() => $aop$(new InvocationContext('MySampleAspect.executeAround',this,'methodExpr',[a,b],{}),() => a-b));

  int get uno => $aop$(new InvocationContext("MySampleAspect.getUno",this,"uno",[],{},getter:true), () => __$uno); int __$uno;   set uno(int value) { $aop$(new InvocationContext("MySampleAspect.getUno",this,"uno",[value],{},setter:true), () => __$uno = value); }
}