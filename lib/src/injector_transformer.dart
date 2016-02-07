library aop.injector_transformer;

import "package:barback/barback.dart";
import "package:aop/injector.dart";
import "package:aop/src/analyzer_transformer.dart" show analyzerResult;
import "package:aop/analyzer.dart" show PointcutDeclaration;

import "dart:async";

class AopInjectorTransformer extends Transformer {
  final BarbackSettings settings;
  Injector injector;

  AopInjectorTransformer.asPlugin(this.settings) {

  }

  String get allowedExtensions => ".dart";

  Future<bool> isPrimary(AssetId id) async => id.path.endsWith(".dart");

  @override
  apply(Transform transform) async {
    if (analyzerResult == null) {
      return;
    }
    //print("INJECTING IN ${transform.primaryInput.id}");
    injector = new Injector();

    injector.interceptors = analyzerResult.pointcutDeclarations.map((PointcutDeclaration pcdecl) => pcdecl.createInterceptor());


    String content = await transform.primaryInput.readAsString();

    String injected = await injector.inject(content,transform.primaryInput.id.path,transform.primaryInput.id.path=="web/index.dart");

    transform.addOutput(new Asset.fromString(transform.primaryInput.id,injected));

  }
}