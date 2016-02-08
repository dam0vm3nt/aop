
class Pippo {
  const Pippo();
}

const Pippo pippo = const Pippo();

class Super {

}

class Mixin {

}

class Sample extends Super with Mixin {
  void methodXYZ(String a, {ciccio}) {
    print(a);
  }

  @pippo
  int methodA(int b, [int x = 10]) {
    return b + x;
  }

  methodVarRet(x, b, z) {
    return x + b - z;
  }

  methodExpr(a,b) => a-b;
}
