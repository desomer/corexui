import 'dart:convert';
import 'dart:io';

import 'web/core/parser/HTMLReader.dart';
import 'web/core/XUIEngine.dart';
import 'web/core/XUIFactory.dart';
import 'web/core/parser/ProviderFile.dart';
import 'web/core/XUIEngine.dart' as Const;


/**
 * 
 *    restdb.io base de donnee online
 *    https://github.com/yissachar/awesome-dart
 */

void main() async {
  final myJsonAsString = '{"a": 1, "b": "c"}';
  final jsond = json.decode(myJsonAsString);
  print('json=' + jsond.toString());

//try {

  var provider = ProviderFile('C:/src_dart/elisys-xui/web/');

  var bufferHtml = XUIHtmlBuffer();

  bool designer = true;

  if (designer) {
    var reader = HTMLReader('app/frameDesigner.html', provider);
    var xuiEngine = XUIEngine();
    var ctx = XUIContext(Const.MODE_FINAL);
    await xuiEngine.start(reader, ctx);
    await xuiEngine.toHTMLString(bufferHtml, "root", ctx);

    print(bufferHtml.html);

    print("write ok size=${bufferHtml.html.length}");
    var path = 'C:/src_dart/elisys-xui/web/index.html';
    new File(path).writeAsStringSync(bufferHtml.html.toString());

  } else {
    var reader = HTMLReader('app/frame1.html', provider);
    var xuiEngine = XUIEngine();
    var ctx = XUIContext(Const.MODE_TEMPLATE);
    await xuiEngine.start(reader, ctx);
    await xuiEngine.toHTMLString(bufferHtml, "root", ctx);

    print(bufferHtml.html);

    print("write ok size=${bufferHtml.html.length}");
    var path = 'c:/xui/assets/test.html';
    new File(path).writeAsStringSync(bufferHtml.html.toString());
  }
}
