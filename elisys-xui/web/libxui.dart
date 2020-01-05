@JS("\$xui")
library xuiapp;

import 'package:js/js.dart';

import 'core/XUIDesignManager.dart';
import 'core/XUIEngine.dart';
import 'core/XUIJSInterface.dart';

@JS()
external void load(obj);

@JS()
external void changeTemplate(obj);

@JS()
external void displayProperties(xid, xid_slot);

@JS('refresh')
external set _refresh(void Function(String) f);

@JS('addDesign')
external set _addDesign(void Function(String, String) f);

@JS('removeDesign')
external set _removeDesign(void Function(String, String) f);

@JS('getInfo')
external set _getInfo(dynamic Function(String, String) f);

@JS('getComponents')
external set _getComponents(dynamic Function(String, String) f);

@JS('getDesignProperties')
external set _getDesignProperties(dynamic Function(String, String) f);

@JS('setDesignProperties')
external set _setDesignProperties(dynamic Function(String, dynamic) f);

///------------------------------------------------------------------

dynamic setDesignProperties(String id, dynamic ret) async {
  List listDesign = ret;
  for (ObjectDesign item in listDesign) {
    if (item.value != item.value_orig) {
      await designManager.changeProperty(item.xid, item.variable, item.value);
    }
  }
  await refresh("template");
  var xid = (listDesign[0] as ObjectDesign).xid;
  displayProperties(xid, xid);
}

dynamic getInfo(String id, String idslot) {
  var info = designManager.xuiEngine.getSlotInfo(id, idslot);

  var InfoJS = SlotInfoJS();
  if (info != null) {
    InfoJS.docId = info.docId;
    InfoJS.idRessource = info.idRessource;
    InfoJS.parentXid = info.parentXid;
    InfoJS.slotname = info.slotname;
    InfoJS.xid = info.xid;
  }
  return InfoJS;
}

dynamic getDesign(String id, String idslot) {
  var designInfo = designManager.getJSDesignInfo(id, idslot);
  var vueParamJS = VueParamJS();
  vueParamJS.xid = designInfo.xid;
  vueParamJS.data = "[" + designInfo.bufData.toString() + "]";
  vueParamJS.template = designInfo.bufTemplate.toString();
  vueParamJS.path = designInfo.bufPath.toString();
  return vueParamJS;
}

dynamic getComponents(String id, String idslot) {
  var designInfo = designManager.getJSComponentInfo(id, idslot);
  var vueParamJS = VueParamJS();
  vueParamJS.xid = designInfo.xid;
  vueParamJS.data = "[" + designInfo.bufData.toString() + "]";
  vueParamJS.template = designInfo.bufTemplate.toString();
  vueParamJS.path = designInfo.bufPath.toString();
  return vueParamJS;
}

void addDesign(String id, String template) async {
  await designManager.addDesign(id, template);
  var mode = "template";
  var ctx = XUIContext(mode);
  var str = await designManager.reloadHtml(ctx, 'app/frame1.html', 'root');
  var ret = Options(mode: mode, html: str);

  changeTemplate(ret);
}

void removeDesign(String id, String modeDelete) async {
  designManager.removeDesign(id, modeDelete);
  var mode = "template";
  var ctx = XUIContext(mode);
  var str = await designManager.reloadHtml(ctx, 'app/frame1.html', 'root');
  var ret = Options(mode: mode, html: str);

  changeTemplate(ret);
}

Future refresh(String mode) async {
  // await addDesign(
  //     "grid-1-row-2-col-0", "<xui-design><h1>test</h1></xui-design>");
  // await addDesign("onglet-tab-0", "<xui-design><span>Info<span></xui-design>");
  // await addDesign("onglet-tab-1", "<xui-design><span>Titre<span></xui-design>");
  // await addDesign("grid-1-row-1", "<xui-design xui-nb=\"5\"></xui-design>");
  // await addDesign("grid-1-row-1-col-2",
  //     "<xui-design><xui-card-1 xid=\"titi\"></xui-card-1><xui-card-1 xid=\"toto\"></xui-card-1></xui-design>");

  var ctx = XUIContext(mode);
  var str = await designManager.reloadHtml(ctx, 'app/frame1.html', 'root');
  var ret = Options(mode: mode, html: str);

  changeTemplate(ret);

  return Future.value();
}

var designManager = XUIDesignManager();

void main() async {
  _refresh = allowInterop(refresh);
  _addDesign = allowInterop(addDesign);
  _removeDesign = allowInterop(removeDesign);
  _getInfo = allowInterop(getInfo);
  _getDesignProperties = allowInterop(getDesign);
  _setDesignProperties = allowInterop(setDesignProperties);
  _getComponents = allowInterop(getComponents);

  String str = await designManager.getHtml(
      XUIContext(MODE_DESIGN), 'app/frame1.html', 'root');
  load(str);
}
