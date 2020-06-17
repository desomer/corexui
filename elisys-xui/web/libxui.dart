@JS("\$xui")
library xuiapp;

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:js';
import 'dart:math';

import 'package:js/js.dart';

import 'core/XUIDesignManager.dart';
import 'core/XUIEngine.dart';
import 'core/XUIFactory.dart';
import 'core/XUIJSInterface.dart';

import 'core/element/XUIElement.dart';
import 'core/parser/HTMLWriter.dart';

@JS()
external void loadPageJS(obj);

@JS()
external void changePageJS(obj);

@JS('refreshXUI')
external set _refresh(void Function(FileDesignInfo) f);

@JS('addDesign')
external set _addDesign(
    void Function(FileDesignInfo, String, String, bool, bool) f);

@JS('getHtmlFrom')
external set _getHtmlFrom(void Function(FileDesignInfo, String) f);

@JS('cutDesign')
external set _cutDesign(void Function(FileDesignInfo, String) f);

@JS('deleteDesign')
external set _deleteDesign(void Function(FileDesignInfo, String) f);

@JS('surroundDesign')
external set _surroundDesign(
    void Function(FileDesignInfo, String, String, String) f);

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
external set _setDesignProperties(dynamic Function(FileDesignInfo, dynamic) f);

@JS('initPage')
external set _initPage(dynamic Function(FileDesignInfo) f);

///------------------------------------------------------------------

/// change les properties
void setDesignProperties(FileDesignInfo fileInfo, dynamic listDesg) async {
  XUIDesignManager designMgr = getDesignManager(fileInfo);
  List listDesign = listDesg;

  for (ObjectDesign item in listDesign) {
    if (item.value != item.value_orig) {
      designMgr.listXidChanged.add(item.xid);
      await designMgr.changeProperty(item.xid, item.variable, item.value);
    }
  }
  fileInfo.mode = "template";

  await _reload(fileInfo);

  // appel la promise
  var xidProp = (listDesign[0] as ObjectDesign).xid;
  context["\$xui"].callMethod("doPromiseJS", ["setDesignProperties", xidProp]);
}

void getDesignProperties(
    FileDesignInfo fileInfo, String id, String idslot) async {
  var designInfo = await getDesignManager(fileInfo).getJSDesignInfo(id, idslot);

  var ret = {
    "xid": designInfo.xid,
    "xidSlot": designInfo.xidSlot,
    "isSlot": id.startsWith(SLOT_PREFIX),
    "data": "[" + designInfo.bufData.toString() + "]",
    "template": designInfo.bufTemplate.toString(),
    "path": designInfo.bufPath.toString()
  };

  // appel la promise
  context["\$xui"]
      .callMethod("doPromiseJS", ["getDesignProperties", JsObject.jsify(ret)]);
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

void addDesign(FileDesignInfo fileInfo, String id, String template, bool reload,
    bool init) async {
  XUIDesignManager designMgr = getDesignManager(fileInfo);
  await designMgr.addDesign(id, template);

  if (!reload && init == true) {
    var ctx = XUIContext(fileInfo.mode);
    // SlotInfo info = designMgr.xuiEngine.getSlotInfo(id, id);
    // print("initHtml addDesign " +fileInfo.xid + " >> " + info.parentXid );
    // fileInfo.xid=info.parentXid;
    await designMgr.initHtml(ctx, fileInfo.file, fileInfo.xid);
  } else {
    if (id != XUI_TRASHCAN_SLOT) designMgr.listXidChanged.add(id);
    if (reload) {
      // voir removeDesign  : evite de faire 2 reload
      await _reload(fileInfo);
    }
  }
}

///****************************************************************** */
String getContentTrashcanID(XUIDesignManager designMgr) {
  SlotInfo infoTrash =
      designMgr.xuiEngine.getSlotInfo(XUI_TRASHCAN_SLOT, XUI_TRASHCAN_SLOT);

  XUIElementHTML contentTrash = infoTrash?.elementHTML?.children?.first;
  var lastDeleteXid = contentTrash?.originElemXUI?.xid;
  return lastDeleteXid;
}

void deleteDesign(FileDesignInfo fileInfo, String id) async {
  XUIDesignManager designMgr = getDesignManager(fileInfo);
  SlotInfo info = designMgr.xuiEngine.getSlotInfo(id, id);
  await designMgr.removeDesign(id, null);
  // lance le reload
  designMgr.listXidChanged.add(info.parentXid);
  await _reload(fileInfo);
}

void cutDesign(FileDesignInfo fileInfo, String id) async {
  XUIDesignManager designMgr = getDesignManager(fileInfo);

  SlotInfo info = designMgr.xuiEngine.getSlotInfo(id, id);

  String lastDeleteXid = getContentTrashcanID(designMgr);

  if (lastDeleteXid != null) {
    // supprime la vielle trashcan
    designMgr.removeDesign(lastDeleteXid, null);
  }

  // ajoute un design a la trashcan
  String slot = "<xui-design xid=\"" + XUI_TRASHCAN_SLOT + "\"></xui-design>";
  await addDesign(fileInfo, XUI_TRASHCAN_SLOT, slot, false, true);

  // move id vers la trashcan
  designMgr.moveDesign(id, null, XUI_TRASHCAN_SLOT);

  // lance le reload
  designMgr.listXidChanged.add(info.parentXid);
  await _reload(fileInfo);
}

void surroundDesign(FileDesignInfo fileInfo, String id, String template,
    String xidSurround) async {
  XUIDesignManager designMgr = getDesignManager(fileInfo);

  SlotInfo info = designMgr.xuiEngine.getSlotInfo(id, id);
  // ajoute un design au tempory
  String slot = "<xui-design xid=\"" + XUI_TEMPORARY_SLOT + "\"></xui-design>";
  await addDesign(fileInfo, XUI_TEMPORARY_SLOT, slot, false, true);

  // move id vers la tempory
  designMgr.moveDesign(id, null, XUI_TEMPORARY_SLOT);

  await addDesign(fileInfo, info.parentXid, template, false, true);

  String targetXid = xidSurround + "-col-0";
  String slotTarget = "<xui-design xid=\"" + targetXid + "\"></xui-design>";
  await addDesign(fileInfo, targetXid, slotTarget, false, true);

  designMgr.moveDesign(id, null, targetXid);

  // lance le reload
  designMgr.listXidChanged.add(info.parentXid);
  await _reload(fileInfo);
}

void moveDesign(FileDesignInfo fileInfo, String id, String idMoveTo) async {
  XUIDesignManager designMgr = getDesignManager(fileInfo);

  if (id == null) {
    // gestion du paste
    id = getContentTrashcanID(designMgr);

    String idClone = getNewXid(idMoveTo, "clone");

    designMgr.cloneDesign(id, idMoveTo, null, idClone);
    designMgr.listXidChanged.add(idMoveTo);

    await _reload(fileInfo);
  } else {
    // ajoute le design qui doit recevoir le composant
    String slot = "<xui-design xid=\"" + idMoveTo + "\"></xui-design>";
    await addDesign(fileInfo, idMoveTo, slot, false, true);
    designMgr.moveDesign(id, null, idMoveTo);
    designMgr.listXidChanged.add(id);
    designMgr.listXidChanged.add(idMoveTo);

    await _reload(fileInfo);
  }
}

String getNewXid(String xidParent, String nameCmp) {
  var d = DateTime.now().millisecondsSinceEpoch.toString();
  d += Random().nextInt(100).toString();

  var idxUUID = xidParent.indexOf("_");
  var pxid = idxUUID == -1 ? xidParent : (xidParent.substring(0, idxUUID));
  var ret = pxid + "-" + nameCmp.replaceFirst("xui-", "") + "_" + d;
  return ret;
}

Future refresh(FileDesignInfo fileInfo) async {
  if (fileInfo.action == "reload") {
    print("reload all from storage");
    XUIDesignManager.removeDesignManager(fileInfo);
    var ctx = XUIContext(MODE_TEMPLATE);
    var designManager = getDesignManager(fileInfo);

    await initStoreVersion(designManager, fileInfo, ctx);
  }

  if (fileInfo.action == "clear") {
    print("clear all from storage");
    XUIDesignManager.removeDesignManager(fileInfo);
    var ctx = XUIContext(MODE_TEMPLATE);
    var designManager = getDesignManager(fileInfo);
    await designManager.initEngine(fileInfo.file, ctx);
  }

  await _reload(fileInfo);
  return Future.value();
}

void getHtmlFrom(FileDesignInfo fileInfo, String idPromise) async {
  var ctx = XUIContext(fileInfo.mode);
  var designMgr = getDesignManager(fileInfo);
  var html;

  if (fileInfo.part == null) {
    html = await designMgr.getHtml(ctx, fileInfo.file, fileInfo.xid);
  } else {
    SlotInfo info =
        designMgr.xuiEngine.getSlotInfo(fileInfo.part, fileInfo.part);
    //print("part = " + info.elementHTML.tag);
    var bufferHtml = XUIHtmlBuffer();
    info.elementHTML.processPhase3(designMgr.xuiEngine, bufferHtml);
    html = bufferHtml.html.toString();
  }

  context["\$xui"].callMethod("doPromiseJS", [idPromise, html]);
}

void _reload(FileDesignInfo fileInfo) async {
  var designMgr = getDesignManager(fileInfo);

  List listReloader = [];
  designMgr.listXidChanged.forEach((key) {
    var reloaderId = designMgr.xuiEngine.getReloaderID(key);
    print("****** reloader : changed xid  " +
        key +
        " => reloader id " +
        (reloaderId ?? "?"));
    if (reloaderId != null) {
      listReloader.add(reloaderId);
    }
  });

  designMgr.listXidChanged.clear();

  var ctx = XUIContext(fileInfo.mode);
  var options = Options(mode: fileInfo.mode);
  if (listReloader.isEmpty) {
    print("****** reloader : all " + ctx.mode);
    var str = await designMgr.getHtml(ctx, fileInfo.file, fileInfo.xid);
    options.html = str;
  } else {
    //print("initHtml _reload " +fileInfo.xid );
    await designMgr.initHtml(ctx, fileInfo.file, fileInfo.xid);
    options.listReloader = listReloader;
  }

  String dataXui = JsonEncoder.withIndent('   ')
      .convert(designMgr.xuiEngine.xuiFile.getObject());
  //final yamld = toYamlString(designMgr.xuiEngine.xuiFile.getObject());
  options.xuidata = dataXui; //yamld.toString();
  options.xuifile = HTMLWriter().toHTMLString(designMgr.xuiEngine.xuiFile);
  options.action = fileInfo.action;
  changePageJS(options);
}

XUIDesignManager getDesignManager(FileDesignInfo fileInfo) {
  return XUIDesignManager.getDesignManager(fileInfo);
}

void main() async {
  _refresh = allowInterop(refresh);
  _addDesign = allowInterop(addDesign);
  _cutDesign = allowInterop(cutDesign);
  _surroundDesign = allowInterop(surroundDesign);
  _moveDesign = allowInterop(moveDesign);
  _getInfo = allowInterop(getInfo);
  _getDesignProperties = allowInterop(getDesignProperties);
  _setDesignProperties = allowInterop(setDesignProperties);
  _getComponents = allowInterop(getComponents);
  _getHtmlFrom = allowInterop(getHtmlFrom);
  _deleteDesign = allowInterop(deleteDesign);
  _initPage = allowInterop(initPage);

  // FileDesignInfo fileInfo = FileDesignInfo();
  // fileInfo.file = 'app/frame1.html';
  // fileInfo.xid = 'root';

  //initPage(fileInfo);

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

Future initPage(FileDesignInfo fileInfo) async {
  print("-------------- start initPage xui ----------------");

  var ctx = XUIContext(MODE_DESIGN);
  var designManager = getDesignManager(fileInfo);

  await initStoreVersion(designManager, fileInfo, ctx);

  String str = await designManager.getHtml(ctx, fileInfo.file, fileInfo.xid);

  loadPageJS(str);
}

Future initStoreVersion(XUIDesignManager designManager, FileDesignInfo fileInfo,
    XUIContext ctx) async {
  var name = "frame1";

  var ver = window.localStorage['xui_version_' + name];
  if (ver != null) {
    int v = int.parse(ver) - 1;
    await designManager.initEngine(fileInfo.file, ctx);

    if (v >= 0) {
      var db = window.localStorage['xui_data_' + name + '_' + v.toString()];

      print("*********** window.localStorage ***********");
      //print(db);
      var saveDb = json.decode(db); //loadYaml(db);

      for (var aDesign in saveDb["design"]) {
        designManager.xuiEngine.xuiFile.addObject(aDesign);
      }
    }
  }
}
