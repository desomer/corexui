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
    await xuiEngine.initialize(reader, ctx);
    await xuiEngine.toHTMLString(bufferHtml, "root", ctx);

    print(bufferHtml.html);

    print("write ok size=${bufferHtml.html.length}");
    var path = 'C:/src_dart/elisys-xui/web/index.html';
    new File(path).writeAsStringSync(bufferHtml.html.toString());
  } else {
    var reader = HTMLReader('app/frame1.html', provider);
    var xuiEngine = XUIEngine();
    var ctx = XUIContext(Const.MODE_TEMPLATE);
    await xuiEngine.initialize(reader, ctx);

    await xuiEngine.addDesign(
        "grid-1-row-2-col-0", "<xui-design><h1>test</h1></xui-design>");
    await xuiEngine.addDesign(
        "onglet-tab-0", "<xui-design><span>Info<span></xui-design>");
    await xuiEngine.addDesign(
        "onglet-tab-1", "<xui-design><span>Titre<span></xui-design>");
    await xuiEngine.addDesign(
        "grid-1-row-1", "<xui-design xui-nb=\"5\"></xui-design>");
    await xuiEngine.addDesign("grid-1-row-1-col-2",
        "<xui-design><xui-card-1 xid=\"titi\"></xui-card-1><xui-card-1 xid=\"toto\"></xui-card-1></xui-design>");

    await xuiEngine.toHTMLString(bufferHtml, "root", ctx);

    var design = xuiEngine.getDesignInfo("onglet-tab-1", "onglet-tab-1");
    var design2 =
        xuiEngine.getDesignInfo("grid-1-row-0-col-0", "grid-1-row-0-col-0");
    var design3 = xuiEngine.getDesignInfo("slot-action-footer", "");

    print(bufferHtml.html);

    print("write ok size=${bufferHtml.html.length}");
    var path = 'c:/xui/assets/test.html';
    new File(path).writeAsStringSync(bufferHtml.html.toString());
  }
}
