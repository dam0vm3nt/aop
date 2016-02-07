class Sample {
  void methodXYZ(String a, {ciccio}) {
    print(a);
  }

  int methodA(int b, [int x = 10]) {
    return b + x;
  }

  methodVarRet(x, b, z) {
    return x + b - z;
  }
}
