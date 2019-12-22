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

  var reader = HTMLReader('app/frame1.html', provider); //vue2frame.html
  var bufferHtml = XUIHtmlBuffer();

  bool designer = true;

  if (designer) {
    await XUIEngine().start(reader, bufferHtml, "frame-vuetify-1-root");
    print(bufferHtml.html);

    print("write ok size=${bufferHtml.html.length}");
    new File('C:/src_dart/elisys-xui/web/index.html')
        .writeAsStringSync(bufferHtml.html.toString());
  } else {
    await XUIEngine().start(reader, bufferHtml, "root"); //frame-vuetify-1

    print(bufferHtml.html);

    print("write ok size=${bufferHtml.html.length}");
//   new File('c:/src_dart/elisys-xui/web/test.html').writeAsStringSync(bufferHtml.html.toString());
    new File('c:/xui/assets/test.html')
        .writeAsStringSync(bufferHtml.html.toString());
  }
// } catch (e) {
//     e.
//     print(e);
// }
}
