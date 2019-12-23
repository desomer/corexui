import 'dart:convert';
import 'dart:io';

import 'web/core/parser/HTMLReader.dart';
import 'web/core/XUIEngine.dart';
import 'web/core/XUIFactory.dart';
import 'web/core/parser/ProviderFile.dart';

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

  bool designer = false;

  if (designer) {
    var reader = HTMLReader('app/frameDesigner.html', provider);
    await XUIEngine().start(reader, bufferHtml, "root");

    print(bufferHtml.html);

    print("write ok size=${bufferHtml.html.length}");
    var path = 'C:/src_dart/elisys-xui/web/index.html';
    new File(path).writeAsStringSync(bufferHtml.html.toString());

  } else {
    var reader = HTMLReader('app/frame1.html', provider);
    await XUIEngine().start(reader, bufferHtml, "root-designer");

    print(bufferHtml.html);

    print("write ok size=${bufferHtml.html.length}");
    var path = 'c:/xui/assets/test.html';
    new File(path).writeAsStringSync(bufferHtml.html.toString());
  }
}
