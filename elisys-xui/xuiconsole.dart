
import 'dart:io';

import 'web/core/parser/HTMLReader.dart';
import 'web/core/XUIEngine.dart';
import 'web/core/XUIFactory.dart';
import 'web/core/parser/ProviderFile.dart';
import 'web/core/XUIEngine.dart' as cst;


///
///    restdb.io base de donnee online
///   https://github.com/yissachar/awesome-dart
///   https://app.netlify.com/sites/elisys/overview
///   https://dashboard.fauna.com/

void main() async {
//  final myJsonAsString = '{"a": 1, "b": "c"}';
//  final jsond = json.decode(myJsonAsString);
//  print('json=' + jsond.toString());

//try {

  var provider = ProviderFile('C:/src_dart/corexui/elisys-xui/web/');

  var bufferHtml = XUIHtmlBuffer();

  bool designer = true;

  if (designer) {
    var reader = HTMLReader('app/frameDesigner.html', provider);
    var xuiEngine = XUIEngine();
    var ctx = XUIContext(cst.MODE_FINAL);
    await xuiEngine.initialize(reader, ctx);
    await xuiEngine.toHTMLString(bufferHtml, "root", ctx);

    print(bufferHtml.html);

    print("write ok size=${bufferHtml.html.length}");
    var path = 'C:/src_dart/corexui/elisys-xui/web/index.html';
    File(path).writeAsStringSync(bufferHtml.html.toString());


  } else {

    var reader = HTMLReader('app/frame2.html', provider);
    var xuiEngine = XUIEngine();
    var ctx = XUIContext(cst.MODE_FINAL);
    await xuiEngine.initialize(reader, ctx);

    // await xuiEngine.addDesign(
    //     "grid-1-row-2-col-0", "<xui-design><h1>test</h1></xui-design>");
    // await xuiEngine.addDesign(
    //     "onglet-tab-0", "<xui-design><span>Info<span></xui-design>");
    // await xuiEngine.addDesign(
    //     "onglet-tab-1", "<xui-design><span>Titre<span></xui-design>");
    // await xuiEngine.addDesign(
    //     "grid-1-row-1", "<xui-design xui-nb=\"5\"></xui-design>");
    // await xuiEngine.addDesign("grid-1-row-1-col-2",
    //     "<xui-design><xui-card-1 xid=\"titi\"></xui-card-1><xui-card-1 xid=\"toto\"></xui-card-1></xui-design>");

   // await XUIActionManager(xuiEngine).addDesign("onglet-tab-0", "<xui-design><xui-card-1 xid='test'><xui-card-1></xui-design>");

    await xuiEngine.toHTMLString(bufferHtml, "root", ctx);

   // XUIActionManager(xuiEngine).removeDesign("onglet", null);

    //await xuiEngine.toHTMLString(bufferHtml, "root", ctx);

    // var design = xuiEngine.getDesignInfo("onglet-tab-1", "onglet-tab-1");
    // var design2 =
    //     xuiEngine.getDesignInfo("grid-1-row-0-col-0", "grid-1-row-0-col-0");
    // var design3 = xuiEngine.getDesignInfo("slot-action-footer", "");

    print(bufferHtml.html);

    print("write ok size=${bufferHtml.html.length}");
    var path = 'C:/src_dart/corexui/elisys-xui/web/frame2.html';
    File(path).writeAsStringSync(bufferHtml.html.toString());
  }
}
