@HtmlImport("sample_comp.html")
library aop_demo.test_comp;

import "package:polymer/polymer.dart";
import "package:web_components/web_components.dart";
import "package:aop_demo/sample.dart";

@PolymerRegister("ciao-ciao")
class MySample extends PolymerElement {

  @reflectable
  void doIt([_,__]) {
    Sample s = new Sample();
    s.methodA(100);
  }

  MySample.created() : super.created();
}