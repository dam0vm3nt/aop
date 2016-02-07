library demo_aop.demo;

import 'package:polymer/init.dart';
import 'package:polymer/polymer.dart';
import "package:reflectable/reflectable.dart";
import "package:aop_demo/sample_comp.dart";
import "dart:html";
//@MirrorsUsed(targets: const ['dart.io.HttpClient', 'dart.io.HttpException',
//  'dart.io.File'])
//import "dart:mirrors" show MirrorsUsed;


import "package:logging/logging.dart";

main() async {

  // Add css for code mirror
  //document.head.appendHtml("<link rel='stylesheet' href='packages/codemirror/addon/hint/show-hint.css' >");

  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.loggerName} - ${rec.message}');
  });

  await initPolymer();
}
