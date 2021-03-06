@JS("\$xui")
library xuiapp;

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:html';
import 'dart:js';

import 'package:js/js.dart';

import 'core/XUIDesignManager.dart';
import 'core/XUIEngine.dart';
import 'core/XUIFactory.dart';
import 'core/XUIJSInterface.dart';

import 'core/element/XUIElement.dart';
import 'core/parser/HTMLWriter.dart';

///------------------------- methode XUI vers JS -----------------------------

@JS()
external void loadPageJS(obj);

@JS()
external void changePageJS(obj);

///-------------------------- methode JS vers XUI ----------------------------
@JS('initPageXUI')
external set _initPageXUI(dynamic Function(FileDesignInfo) f);

@JS('refreshPageXUI')
external set _refreshPageXUI(void Function(FileDesignInfo) f);

@JS('addDesignXUI')
external set _addDesignXUI(
    void Function(FileDesignInfo, String, String, bool, bool) f);

@JS('getHtmlFromXUI')
external set _getHtmlFromXUI(void Function(FileDesignInfo, String) f);

@JS('cutDesign')
external set _cutDesign(void Function(FileDesignInfo, String) f);

@JS('copyDesign')
external set _copyDesign(void Function(FileDesignInfo, String) f);

@JS('deleteDesign')
external set _deleteDesign(void Function(FileDesignInfo, String) f);

@JS('surroundDesign')
external set _surroundDesign(
    void Function(FileDesignInfo, String, String, String) f);

@JS('moveDesign')
external set _moveDesign(void Function(FileDesignInfo, String, String) f);

@JS('changeNbChildXUI')
external set _changeNbChildXUI(void Function(FileDesignInfo, String, String) f);

@JS('getInfoXUI')
external set _getInfoXUI(dynamic Function(FileDesignInfo, String, String) f);

@JS('getComponentsXUI')
external set _getComponentsXUI(
    dynamic Function(FileDesignInfo, String, String) f);

@JS('getActionsXUI')
external set _getActionsXUI(
    dynamic Function(FileDesignInfo, String, String, String) f);

/// retourne les properties
@JS('getDesignProperties')
external set _getDesignProperties(
    void Function(FileDesignInfo, String, String) f);

/// change les properties
@JS('setDesignProperties')
external set _setDesignProperties(dynamic Function(FileDesignInfo, dynamic) f);

///------------------------------------------------------------------
Future initPageXUI(FileDesignInfo fileInfo) async {
  print("-------------- start initPage xui ----------------");

  var ctx = XUIContext(fileInfo.mode);
  var designManager = _getDesignManager(fileInfo);

  await _initStoreVersion(designManager, fileInfo, ctx);

  String str = await designManager.getHtml(ctx, fileInfo.file, fileInfo.xid);

  loadPageJS(str);
}

// recharge la page  (reload ou clear)
Future refreshPageXUI(FileDesignInfo fileInfo) async {
  if (fileInfo.action == "reload") {
    print("reload all from storage");
    XUIDesignManager.removeDesignManager(fileInfo);
    var ctx = XUIContext(MODE_TEMPLATE);
    var designManager = _getDesignManager(fileInfo);

    await _initStoreVersion(designManager, fileInfo, ctx);
  }

  if (fileInfo.action == "clear") {
    print("clear all from storage");
    XUIDesignManager.removeDesignManager(fileInfo);
    var ctx = XUIContext(MODE_TEMPLATE);
    var designManager = _getDesignManager(fileInfo);
    await designManager.initEngine(fileInfo.file, ctx);
  }

  await _reload(fileInfo);
  return Future.value();
}

/// change les properties
void setDesignProperties(FileDesignInfo fileInfo, dynamic listDesig) async {
  XUIDesignManager designMgr = _getDesignManager(fileInfo);
  List listDesign = listDesig;

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
  var designInfo =
      await _getDesignManager(fileInfo).getJSDesignInfo(id, idslot);

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

/// Retourne la liste des composants
dynamic getComponentsXUI(FileDesignInfo fileInfo, String id, String idslot) {
  var designInfo = _getDesignManager(fileInfo).getJSComponentInfo(id, idslot);
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
dynamic getInfoXUI(FileDesignInfo fileInfo, String id, String idslot) {
  var engine = _getDesignManager(fileInfo).xuiEngine;
  var info = engine.getSlotInfo(id, idslot);

  var InfoJS = SlotInfoJS();
  if (info != null) {
    InfoJS.docId = info.docId;
    InfoJS.idRessource = info.idRessource;
    InfoJS.parentXid = info.parentXid;
    InfoJS.slotname = info.slotname;
    InfoJS.xid = info.xid;
    DocInfo doc = engine.docInfo[info.docId];
    if (doc == null) {
      //recherche la doc du parent
      int idx = info.docId.indexOf(":");
      if (idx > 0) {
        var docId = info.docId.substring(idx + 1);
        doc = engine.docInfo[docId];
      }
    }
    InfoJS.addRemoveAction = doc?.addRemove;
  }
  return InfoJS;
}

void addDesignXUI(FileDesignInfo fileInfo, String id, String template,
    bool reload, bool init) async {
  XUIDesignManager designMgr = _getDesignManager(fileInfo);
  await designMgr.addDesign(id, template);

  if (!reload && init == true) {
    var ctx = XUIContext(fileInfo.mode);
    await designMgr.initHtml(ctx, fileInfo.file, fileInfo.xid);
  } else {
    if (id != XUI_COPYZONE_SLOT) designMgr.listXidChanged.add(id);
    if (reload) {
      // voir removeDesign  : evite de faire 2 reload
      await _reload(fileInfo);
    }
  }
}

///****************************************************************** */

void deleteDesign(FileDesignInfo fileInfo, String id) async {
  XUIDesignManager designMgr = _getDesignManager(fileInfo);
  SlotInfo info = designMgr.xuiEngine.getSlotInfo(id, id);
  await designMgr.removeDesign(id, null);
  // lance le reload
  designMgr.listXidChanged.add(info.parentXid);
  await _reload(fileInfo);
}

void cutDesign(FileDesignInfo fileInfo, String id) async {
  XUIDesignManager designMgr = _getDesignManager(fileInfo);

  SlotInfo info = designMgr.xuiEngine.getSlotInfo(id, id);

  String lastCopyXid = _getContentCopyZoneID(designMgr);

  if (lastCopyXid != null) {
    // supprime la vielle trashcan
    designMgr.removeDesign(lastCopyXid, null);
  }

  // ajoute un design a la trashcan
  String slot = "<xui-design xid=\"" + XUI_COPYZONE_SLOT + "\"></xui-design>";
  await addDesignXUI(fileInfo, XUI_COPYZONE_SLOT, slot, false,
      true); //todo ajout direct xuiDesign

  // move id vers la trashcan
  designMgr.moveDesign(id, null, XUI_COPYZONE_SLOT);

  // lance le reload
  designMgr.listXidChanged.add(info.parentXid);
  await _reload(fileInfo);
}

void copyDesign(FileDesignInfo fileInfo, String id) async {
  XUIDesignManager designMgr = _getDesignManager(fileInfo);

  String lastCopyXid = _getContentCopyZoneID(designMgr);

  if (lastCopyXid != null) {
    // supprime la vielle trashcan
    designMgr.removeDesign(lastCopyXid, null);
  }

  // ajoute un design a la trashcan
  // String slot = "<xui-design xid=\"" + XUI_COPYZONE_SLOT + "\"></xui-design>";
  // await addDesign(fileInfo, XUI_COPYZONE_SLOT, slot, false, true);

  designMgr.addXUIDesignEmpty(XUI_COPYZONE_SLOT);

  // move id vers la trashcan
  designMgr.cloneDesign(id, XUI_COPYZONE_SLOT, null);

  // lance le reload
  designMgr.listXidChanged.add(id);
  await _reload(fileInfo);
}

void surroundDesign(FileDesignInfo fileInfo, String id, String template,
    String xidSurround) async {
  XUIDesignManager designMgr = _getDesignManager(fileInfo);

  SlotInfo info = designMgr.xuiEngine.getSlotInfo(id, id);
  var xidParent = info.parentXid;
  // ajoute un design au tempory
  designMgr.addXUIDesignEmpty(XUI_TEMPORARY_SLOT);

  // move id vers la tempory
  designMgr.moveDesign(id, null, XUI_TEMPORARY_SLOT);

  await addDesignXUI(fileInfo, xidParent, template, false, true);

  String targetXid = xidSurround + "-col-0";
  designMgr.addXUIDesignEmpty(targetXid);
  designMgr.moveDesign(id, null, targetXid);

  // lance le reload
  designMgr.listXidChanged.add(xidParent);
  await _reload(fileInfo);
}

void moveDesign(FileDesignInfo fileInfo, String id, String idMoveTo) async {
  XUIDesignManager designMgr = _getDesignManager(fileInfo);

  if (id == null) {
    // gestion du move avec clone ( ex : copy, paste)
    id = _getContentCopyZoneID(designMgr);
    designMgr.cloneDesign(id, idMoveTo, null);
    designMgr.listXidChanged.add(idMoveTo);

    await _reload(fileInfo);
  } else {
    // gestion du move (ex : drag)
    designMgr.addXUIDesignEmpty(idMoveTo);
    designMgr.moveDesign(id, null, idMoveTo);
    designMgr.listXidChanged.add(id);
    designMgr.listXidChanged.add(idMoveTo);

    await _reload(fileInfo);
  }
}

/// change les enfant avec le nb (ex: tab, grid, etc...)
void changeNbChildXUI(
    FileDesignInfo fileInfo, String idSlot, String action) async {
  var designManager = _getDesignManager(fileInfo);
  SlotInfo infoSlot = designManager.xuiEngine.getSlotInfo(idSlot, idSlot);
  SlotInfo infoContainer = designManager.xuiEngine
      .getSlotInfo(infoSlot.parentXid, infoSlot.parentXid);


  var nbItem = int.parse(infoContainer.elementHTML.propertiesXUI["nb"].content);

  print(
      "changeChild " + action + " " + idSlot + " nbItem " + nbItem.toString());

  if (action != "delete") {
    // ajoute un slot en incrementant le nb
    await designManager.changeProperty(
        infoSlot.parentXid, "nb", (nbItem + 1).toString());
  }

  var idx = idSlot.lastIndexOf("-") + 1;
  var suffix = idSlot.substring(0, idx);
  var prefix = idSlot.substring(idx);
  var startItem = int.parse(prefix);

  if (action == "prev") {
    startItem = startItem - 1;
  }

  // decalage des enfants
  if (action == "delete") {
    for (var i = startItem; i < nbItem; i++) {
      // decalage des enfant vers la gauche
      await _doMoveChildByIdx(suffix, i, i - 1, designManager, fileInfo);
      if (infoContainer.docId == "xui-tabs") {
        await _doMoveChildByIdx(
            suffix + "item-", i, i - 1, designManager, fileInfo);
      }
    }
  } else {
    for (var i = nbItem - 1; i > startItem; i--) {
      // decalage des enfant vers la droite
      await _doMoveChildByIdx(suffix, i, i + 1, designManager, fileInfo);
      if (infoContainer.docId == "xui-tabs") {
        await _doMoveChildByIdx(
            suffix + "item-", i, i + 1, designManager, fileInfo);
      }
    }
  }

  if (action == "delete") {
    if (nbItem - 1 == 0) {
      return await deleteDesign(fileInfo, infoSlot.parentXid);
    }

    // retire un slot
    await designManager.changeProperty(
        infoSlot.parentXid, "nb", (nbItem - 1).toString());
  }

  designManager.listXidChanged.add(infoSlot.parentXid);
  await _reload(fileInfo);
}

Future _doMoveChildByIdx(String suffix, int i, int idst,
    XUIDesignManager designManager, FileDesignInfo fileInfo) async {
  var idSlotToMove = suffix + i.toString();
  var idSlotToDest = suffix + idst.toString();
  //SlotInfo infoSlot = designManager.xuiEngine.getSlotInfo(idSlotToMove, idSlotToMove);
  //
  var listDesign = designManager.xuiEngine.xuiFile.designs[idSlotToMove];
  if (listDesign != null) {
    var xuiDesign =
        listDesign.sort(designManager.xuiEngine.xuiFile.context).first;
    var id = ((xuiDesign.elemXUI.children.first) as XUIElementXUI).xid;
    print("move => " + id + " to " + idSlotToDest);
    inspect(xuiDesign.elemXUI);

    // ajoute le design qui doit recevoir le composant
    designManager.addXUIDesignEmpty(idSlotToDest);
    //String slot = "<xui-design xid=\"" + idSlotToDest + "\"></xui-design>";
    //await addDesign(fileInfo, idSlotToDest, slot, false, true);
    var ctx = XUIContext(fileInfo.mode);
    await designManager.initHtml(ctx, fileInfo.file, fileInfo.xid);

    designManager.moveDesign(id, null, idSlotToDest);
  }
}

/// retourne le code html d'un xui
void getHtmlFromXUI(FileDesignInfo fileInfo, String idPromise) async {
  var ctx = XUIContext(fileInfo.mode);
  var designMgr = _getDesignManager(fileInfo);
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
  var designMgr = _getDesignManager(fileInfo);

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
    await designMgr.initHtml(ctx, fileInfo.file, fileInfo.xid);
    options.listReloader = listReloader;
  }

  String dataXui = JsonEncoder.withIndent('   ') //null
      .convert(designMgr.xuiEngine.xuiFile.getObjects());

  options.xuidata = dataXui;
  options.xuifile = HTMLWriter().toHTMLString(designMgr.xuiEngine.xuiFile);
  options.action = fileInfo.action;
  changePageJS(options);
}

dynamic getActionsXUI(
    FileDesignInfo fileInfo, String id, String idSlot, String action) {
  print("-------------- getActionsXUI ----------------   " + action);

  var ctx = XUIContext(MODE_DESIGN);
  var designManager = _getDesignManager(fileInfo);

  return designManager.getActionsPopup(ctx, id, idSlot, action);
}

void main() async {
  _refreshPageXUI = allowInterop(refreshPageXUI);
  _addDesignXUI = allowInterop(addDesignXUI);
  _cutDesign = allowInterop(cutDesign);
  _copyDesign = allowInterop(copyDesign);
  _surroundDesign = allowInterop(surroundDesign);
  _moveDesign = allowInterop(moveDesign);
  _changeNbChildXUI = allowInterop(changeNbChildXUI);
  _getInfoXUI = allowInterop(getInfoXUI);
  _getDesignProperties = allowInterop(getDesignProperties);
  _setDesignProperties = allowInterop(setDesignProperties);
  _getComponentsXUI = allowInterop(getComponentsXUI);
  _getHtmlFromXUI = allowInterop(getHtmlFromXUI);
  _deleteDesign = allowInterop(deleteDesign);
  _initPageXUI = allowInterop(initPageXUI);
  _getActionsXUI = allowInterop(getActionsXUI);
}

XUIDesignManager _getDesignManager(FileDesignInfo fileInfo) {
  return XUIDesignManager.getDesignManager(fileInfo);
}

Future _initStoreVersion(XUIDesignManager designManager,
    FileDesignInfo fileInfo, XUIContext ctx) async {
  var name = fileInfo.fileID;

  var ver = window.localStorage['xui_version_' + name];
  if (ver != null) {
    int v = int.parse(ver) - 1;

    // force une page vide pour pouvoir tous surcharger
    var fileName = 'app/frame0Empty.html'; //fileInfo.file;

    await designManager.initEngine(fileName, ctx);

    if (v >= 0) {
      var db = window.localStorage['xui_data_' + name + '_' + v.toString()];

      print("*********** window.localStorage ***********");
      //print(db);
      var saveDb = json.decode(db); //loadYaml(db);

      for (var aDesign in saveDb["design"]) {
        designManager.xuiEngine.xuiFile.addObjectDesign(aDesign);
      }
      for (var anImport in saveDb["import"]) {
        //designManager.xuiEngine.xuiFile.addObjectImport(anImport);
      }
      for (var aCmp in saveDb["component"]) {
        //designManager.xuiEngine.xuiFile.addObjectCmp(aCmp);
      }
    }
  }
}

String _getContentCopyZoneID(XUIDesignManager designMgr) {
  SlotInfo infoTrash =
      designMgr.xuiEngine.getSlotInfo(XUI_COPYZONE_SLOT, XUI_COPYZONE_SLOT);

  XUIElementHTML contentTrash = infoTrash?.elementHTML?.children?.first;
  var lastDeleteXid = contentTrash?.originElemXUI?.xid;
  return lastDeleteXid;
}
