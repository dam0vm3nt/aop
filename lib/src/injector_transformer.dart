library aop.injector_transformer;

import "dart:async";

import "package:aop/src/analyzer.dart" show PointcutDeclaration,AnalyzerResult;
import "package:aop/src/injector.dart";
import "package:barback/barback.dart";

class AopInjectorTransformer extends Transformer {
  final BarbackSettings settings;
  Injector injector;

  AopInjectorTransformer.asPlugin(this.settings) {

  }

  String get allowedExtensions => ".dart";

  Future<bool> isPrimary(AssetId id) async => id.path.endsWith(".dart");

  @override
  apply(Transform transform) async {
    AnalyzerResult analyzerResult = settings.configuration["analyzer_result_holder"][0];
    if (analyzerResult == null) {
      return;
    }
    //print("INJECTING IN ${transform.primaryInput.id}");
    injector = new Injector();

    injector.interceptors = analyzerResult.pointcutDeclarations.map((PointcutDeclaration pcdecl) => pcdecl.createInterceptor());


    String content = await transform.primaryInput.readAsString();
    var url = transform.primaryInput.id.path.startsWith('lib/')
          ? 'package:${transform.primaryInput.id.package}/${transform.primaryInput.id.path.substring(4)}'
          : transform.primaryInput.id.path;

    String injected = injector.inject(content,url,settings.configuration["entry_points"].contains(transform.primaryInput.id.path));

    Asset result;
    if (injected!=null) {
      print("TRANS: ${transform.primaryInput.id}");
      result = new Asset.fromString(transform.primaryInput.id,injected);
    } else {
      result = transform.primaryInput;
    }
    transform.addOutput(result);

  }
}