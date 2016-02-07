
import "package:barback/barback.dart";

import "package:aop/src/analyzer_transformer.dart";
import "package:aop/src/injector_transformer.dart";

class AopTransformer implements TransformerGroup {
  List<List<Transformer>> phases;

  AopTransformer.asPlugin(BarbackSettings settings) {

    phases = [
      [
        new AopAnalyzerTransformer.asPlugin(new BarbackSettings({},settings.mode))
      ],
      [
        new AopInjectorTransformer.asPlugin(new BarbackSettings({},settings.mode))
      ]
    ];
  }


}