
class Pippo {
  const Pippo();
}

const Pippo pippo = const Pippo();

class Sample {
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

  @pippo
  int uno;
}
