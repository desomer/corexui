@JS("\$xui")
library xuiapp;

import 'package:js/js.dart';

import 'PageManager.dart';
import 'core/XUIEngine.dart';

@JS()
external void load(obj);

@JS()
external void changeTemplate(obj);

@JS('refresh')
external set _refresh(void Function(String) f);

@JS('addDesign')
external set _addDesign(void Function(String, String) f);

@JS('getInfo')
external set _getInfo(dynamic Function(String, String) f);

@JS()
@anonymous
class Options {
  external String get mode;
  external String get html;
  external factory Options({String mode, dynamic html});
}

/**************************************************************************** */
dynamic getInfo(String id, String idslot) {
  var info = pageManager.xuiEngine.mapInfo[id];
  if (info == null) info = pageManager.xuiEngine.mapInfo[idslot];
  return info;
}

void addDesign(String id, String template) async {
  await pageManager.addDesign(id, template);
}

void refresh(String mode) async {
  await addDesign(
      "grid-1-row-2-col-0", "<xui-design><h1>test</h1></xui-design>");
  await addDesign("onglet-tab-0", "<xui-design><span>Info<span></xui-design>");
  await addDesign("onglet-tab-1", "<xui-design><span>Titre<span></xui-design>");
  await addDesign("grid-1-row-1", "<xui-design xui-nb=\"5\"></xui-design>");
  await addDesign("grid-1-row-1-col-2",
      "<xui-design><xui-card-1 xid=\"titi\"></xui-card-1><xui-card-1 xid=\"toto\"></xui-card-1></xui-design>");

  String str =
      await pageManager.reloadHtml(XUIContext(mode), 'app/frame1.html', 'root');
  var ret = new Options(mode: mode, html: str);

  changeTemplate(ret);
}

//document.querySelector("#rootFrame").contentWindow.postMessage({ "json_example": true }, "*");

PageManager pageManager = PageManager();

void main() async {
  _refresh = allowInterop(refresh);
  _addDesign = allowInterop(addDesign);
  _getInfo = allowInterop(getInfo);

  String str = await pageManager.getHtml(
      XUIContext(MODE_DESIGN), 'app/frame1.html', 'root');
  load(str);
}
