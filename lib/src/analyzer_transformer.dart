library aop.analyzer_transformer;

import "package:barback/barback.dart";
import "package:aop/analyzer.dart";

AnalyzerResult analyzerResult;

class AopAnalyzerTransformer extends AggregateTransformer {

  BarbackSettings settings;

  AopAnalyzerTransformer.asPlugin(this.settings);

  @override
  apply(AggregateTransform transform) async {

    Analyzer analyzer = new Analyzer();

    analyzer.start();

    await for (Asset asset in transform.primaryInputs) {
      print("Analyzing ${asset.id}");

      String content =  await asset.readAsString();

      String path=asset.id.path;
      if (path.startsWith("lib/")) {
        path = path.substring(4);
      }

      analyzer.analyze(content,"package:${asset.id.package}/${path}");

    }
    analyzerResult = analyzer.end();

    AssetId initId = new AssetId(transform.package,"web/aop_initializer.dart");
    print("WRITE aopInitializer for: ${transform.package} : ${initId}");
    transform.addOutput(new Asset.fromString(initId,analyzerResult.initializer));

  }

  @override
  classifyPrimary(AssetId id) {
    if (id.path.endsWith(".dart")) {
      return "dart";
    }

    return null;
  }
}