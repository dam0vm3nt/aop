
import "package:barback/barback.dart";

import "package:aop/src/analyzer_transformer.dart";
import "package:aop/src/injector_transformer.dart";

class AopTransformer implements TransformerGroup {
  List<List<Transformer>> phases;

  AopTransformer.asPlugin(BarbackSettings settings) {
    List  holder= new List(1);

    phases = [
      [
        new AopAnalyzerTransformer.asPlugin(new BarbackSettings({"analyzer_result_holder":holder},settings.mode))
      ],
      [
        new AopInjectorTransformer.asPlugin(new BarbackSettings({"analyzer_result_holder":holder,"entry_points":settings.configuration["entry_points"]},settings.mode))
      ]
    ];
  }


}