@JS("\$xui")
library xuiapp;

import 'dart:async';
import 'dart:js';

import 'package:js/js.dart';

import 'core/XUIDesignManager.dart';
import 'core/XUIEngine.dart';
import 'core/XUIJSInterface.dart';

import 'package:yamlicious/yamlicious.dart' show toYamlString;

@JS()
external void loadPageJS(obj);

@JS()
external void loadCodeYamlJS(obj);

@JS()
external void changePageJS(obj);

@JS()
external void displayPropertiesJS(xid, xid_slot);

@JS()
external void loadPropertiesJS(paramJS);

@JS('refresh')
external set _refresh(void Function(FileDesignInfo) f);

@JS('addDesign')
external set _addDesign(void Function(FileDesignInfo, String, String) f);

@JS('getHtmlFrom')
external set _getHtmlFrom(void Function(FileDesignInfo, String) f);

@JS('removeDesign')
external set _removeDesign(void Function(FileDesignInfo, String) f);

@JS('deleteDesign')
external set _deleteDesign(void Function(FileDesignInfo, String) f);

@JS('moveDesign')
external set _moveDesign(void Function(FileDesignInfo, String, String) f);

@JS('getInfo')
external set _getInfo(dynamic Function(FileDesignInfo, String, String) f);

@JS('getComponents')
external set _getComponents(dynamic Function(FileDesignInfo, String, String) f);

@JS('getDesignProperties')
external set _getDesignProperties(
    void Function(FileDesignInfo, String, String) f);

@JS('setDesignProperties')
external set _setDesignProperties(
    dynamic Function(FileDesignInfo, String, dynamic, String) f);

///------------------------------------------------------------------

void setDesignProperties(
    FileDesignInfo fileInfo, String idAction, dynamic listDesg, String idPromise) async {
  List listDesign = listDesg;
  for (ObjectDesign item in listDesign) {
    if (item.value != item.value_orig) {
      await getDesignManager(fileInfo)
          .changeProperty(item.xid, item.variable, item.value);
    }
  }
  fileInfo.mode = "template";
  await refresh(fileInfo);

  var xidProp = (listDesign[0] as ObjectDesign).xid;
  context["\$xui"].callMethod("doPromiseJS", [idPromise, xidProp]);

}

void getDesignProperties(
    FileDesignInfo fileInfo, String id, String idslot) async {
  var designInfo = await getDesignManager(fileInfo).getJSDesignInfo(id, idslot);
  var vueParamJS = VueParamJS();
  vueParamJS.xid = designInfo.xid;
  vueParamJS.xidSlot = designInfo.xidSlot;
  vueParamJS.isSlot = id.startsWith(SLOT_PREFIX);
  vueParamJS.data = "[" + designInfo.bufData.toString() + "]";
  vueParamJS.template = designInfo.bufTemplate.toString();
  vueParamJS.path = designInfo.bufPath.toString();
  loadPropertiesJS(vueParamJS);
}

dynamic getComponents(FileDesignInfo fileInfo, String id, String idslot) {
  var designInfo = getDesignManager(fileInfo).getJSComponentInfo(id, idslot);
  var vueParamJS = VueParamJS();
  vueParamJS.xid = designInfo.xid;
  vueParamJS.xidSlot = designInfo.xidSlot;
  vueParamJS.isSlot = id.startsWith(SLOT_PREFIX);
  vueParamJS.data = "[" + designInfo.bufData.toString() + "]";
  vueParamJS.template = designInfo.bufTemplate.toString();
  vueParamJS.path = designInfo.bufPath.toString();
  return vueParamJS;
}

/// retourne les info d'un xid
dynamic getInfo(FileDesignInfo fileInfo, String id, String idslot) {
  var info = getDesignManager(fileInfo).xuiEngine.getSlotInfo(id, idslot);

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

void addDesign(FileDesignInfo fileInfo, String id, String template) async {
  await getDesignManager(fileInfo).addDesign(id, template);
  var ctx = XUIContext(fileInfo.mode);
  var str = await getDesignManager(fileInfo)
      .getHtml(ctx, fileInfo.file, fileInfo.xid);
  var ret = Options(mode: fileInfo.mode, html: str);

  _reload(fileInfo, ret);
}


void deleteDesign(FileDesignInfo fileInfo, String id) async {
    XUIDesignManager designMgr = getDesignManager(fileInfo);
    await designMgr.removeDesign(id, null);
}

void removeDesign(FileDesignInfo fileInfo, String id) async {

  XUIDesignManager designMgr = getDesignManager(fileInfo);

  if (designMgr.xuiEngine.lastDeleteXid != null) {
    // supprime la vielle trashcan 
    designMgr.removeDesign(designMgr.xuiEngine.lastDeleteXid, null);
  }

  // ajoute un design a la trashcan
  String moveToTrachcan = "xui-trashcan-slot";
  designMgr.xuiEngine.lastDeleteXid = id;
  String slot = "<xui-design xid=\"" + moveToTrachcan + "\"></xui-design>";
  await addDesign(fileInfo, moveToTrachcan, slot);

  // move id vers la trashcan
  designMgr.moveDesign(id, null, moveToTrachcan);

  var ctx = XUIContext(fileInfo.mode);
  var str = await designMgr.getHtml(ctx, fileInfo.file, fileInfo.xid);
  var ret = Options(mode: fileInfo.mode, html: str);
  _reload(fileInfo, ret);
}

void moveDesign(FileDesignInfo fileInfo, String id, String idMoveTo) async {
  XUIDesignManager designMgr = getDesignManager(fileInfo);


  String slot = "<xui-design xid=\"" + idMoveTo + "\"></xui-design>";
  await addDesign(fileInfo, idMoveTo, slot);
  if (id==null) {
    id=designMgr.xuiEngine.lastDeleteXid;
    designMgr.xuiEngine.lastDeleteXid=null;
  }

  designMgr.moveDesign(id, null, idMoveTo);
  var ctx = XUIContext(fileInfo.mode);
  var str = await designMgr.getHtml(ctx, fileInfo.file, fileInfo.xid);
  var ret = Options(mode: fileInfo.mode, html: str);

  _reload(fileInfo, ret);
}

Future refresh(FileDesignInfo fileInfo) async {
  var ctx = XUIContext(fileInfo.mode);
  var str = await getDesignManager(fileInfo)
      .getHtml(ctx, fileInfo.file, fileInfo.xid);
  var ret = Options(mode: fileInfo.mode, html: str);

  _reload(fileInfo, ret);

  return Future.value();
}

void getHtmlFrom(FileDesignInfo fileInfo, String idPromise) async {
  var ctx = XUIContext(fileInfo.mode);
  var html = await getDesignManager(fileInfo)
      .getHtml(ctx, fileInfo.file, fileInfo.xid);

  context["\$xui"].callMethod("doPromiseJS", [idPromise, html]);
}

void _reload(FileDesignInfo fileInfo, var options) {
  dynamic obj = getDesignManager(fileInfo).xuiEngine.xuiFile.getObject();

  // final jsond = json.encode(obj);
  // print('json=' + jsond.toString());

  final yamld = toYamlString(obj);
  loadCodeYamlJS(yamld.toString());

  changePageJS(options);
}

XUIDesignManager getDesignManager(FileDesignInfo fileInfo) {
  return XUIDesignManager.getDesignManager(fileInfo);
}

void main() async {
  print("-------------- start xui ----------------");
  // context['console'].callMethod('log', ["------------ start xui 2"]);

  _refresh = allowInterop(refresh);
  _addDesign = allowInterop(addDesign);
  _removeDesign = allowInterop(removeDesign);
  _moveDesign = allowInterop(moveDesign);
  _getInfo = allowInterop(getInfo);
  _getDesignProperties = allowInterop(getDesignProperties);
  _setDesignProperties = allowInterop(setDesignProperties);
  _getComponents = allowInterop(getComponents);
  _getHtmlFrom = allowInterop(getHtmlFrom);
  _deleteDesign = allowInterop(deleteDesign);

  FileDesignInfo fileInfo = FileDesignInfo();
  fileInfo.file = 'app/frame1.html';
  fileInfo.xid = 'root';

  String str = await getDesignManager(fileInfo)
      .getHtml(XUIContext(MODE_DESIGN), fileInfo.file, fileInfo.xid);

  loadPageJS(str);

  // var w = Worker('libxuiworker.js');   //libxuiworker.dart.js

  // // Listen to Worker's postMessage().
  // // dart.html convert the callback to a Stream.
  // w.onMessage.listen((msg) {
  //   print('master took back '+msg.data);
  // });

  // // After one second, post a message to the Worker.
  // new Timer(Duration(seconds:10), () {
  //   print("-------------SEND  --------------");
  //   w.postMessage("ok");
  // });

}
