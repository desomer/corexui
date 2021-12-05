@JS("\$xuicore")
library xuiapp;

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:html';

import 'package:js/js.dart';

import 'core/XUIConfigManager.dart';
import 'core/XUIDesignManager.dart';
import 'core/XUIEngine.dart';
import 'core/XUIFactory.dart';
import 'core/XUIJSInterface.dart';

import 'core/XUISlotTreeManager.dart';
import 'core/element/XUIElement.dart';
import 'core/element/XUIProperty.dart';
import 'core/parser/HTMLWriter.dart';
import 'core/parser/ObjectWriter.dart';


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

@JS('cutDesignXUI')
external set _cutDesignXUI(void Function(FileDesignInfo, String) f);

@JS('copyDesignXUI')
external set _copyDesignXUI(void Function(FileDesignInfo, String) f);

@JS('deleteDesignXUI')
external set _deleteDesignXUI(void Function(FileDesignInfo, String) f);

@JS('surroundDesignXUI')
external set _surroundDesignXUI(
    void Function(FileDesignInfo, String, String, String) f);

@JS('moveDesignXUI')
external set _moveDesignXUI(void Function(FileDesignInfo, String, String) f);

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



@JS('getEventMethodsXUI')
external set _getEventMethodsXUI(
    dynamic Function(FileDesignInfo) f);

/// retourne les properties
@JS('getDesignPropertiesXUI')
external set _getDesignPropertiesXUI(
    void Function(FileDesignInfo, String, String) f);

/// change les properties
@JS('saveDesignPropertiesXUI')
external set _saveDesignPropertiesXUI(
    dynamic Function(FileDesignInfo, dynamic) f);

///------------------------------------------------------------------
Future initPageXUI(FileDesignInfo fileInfo) async {
  XUIConfigManager.printc("-------------- start initPage xui ----------------");
  XUIDesignManager.removeDesignManager(fileInfo);
  var ctx = XUIContext(fileInfo.mode);
  var designManager = _getDesignManager(fileInfo);

  await _initStoreVersion(designManager, fileInfo, ctx);

  String? str = await designManager.getHtml(ctx, fileInfo.file, fileInfo.xid);

  var options = Options(mode: fileInfo.mode);

  // XUIProperty? propBinding =
  //     designManager.getXUIEngine().getXUIPropertyFromDesign("root", "binding");
  // String? lastBinding = propBinding?.content;

  //options.binding = designManager.getXUIEngine().getBindingInfo();
  options.treeSlot = new XUISlotTreeManager(designManager.getXUIEngine()).getSlotTree();
  //options.dataState = "{" + (lastBinding ?? "") + "}";

  XUIProperty? propConfig =  designManager.getXUIEngine().getXUIPropertyFromDesign("root", "appConfig");
  options.appConfig=propConfig?.content?.toString() ?? "";

  loadPageJS(str, options);
}

// recharge la page  (reload ou clear)
Future refreshPageXUI(FileDesignInfo fileInfo) async {
  XUIConfigManager.printc("--- CORE --- refreshPageXUI ["+fileInfo.mode + "] action ["+fileInfo.action+"] id="+fileInfo.xid);

  if (fileInfo.action == "reload") {
    print("reload all from storage");
    XUIDesignManager.removeDesignManager(fileInfo);
    var ctx = XUIContext(MODE_TEMPLATE);
    var designManager = _getDesignManager(fileInfo);

    await _initStoreVersion(designManager, fileInfo, ctx);
  }

  if (fileInfo.action == "reload-json") {
    var newBinding = generateApplicationStateJS(
        "", ""); // affecte le text de l'editor uniquement
    var designManager = _getDesignManager(fileInfo);
    await designManager.changeProperty("root", "binding", newBinding, "");
  }

  if (fileInfo.action == "clear") {
    print("clear all from storage");
    XUIDesignManager.removeDesignManager(fileInfo);
    var ctx = XUIContext(MODE_TEMPLATE);
    var designManager = _getDesignManager(fileInfo);
    await designManager.initEngine(fileInfo.file, ctx);
  }

  await _reloadTemplate(fileInfo);
  return Future.value();
}

/// change les properties
void saveDesignPropertiesXUI(FileDesignInfo fileInfo, dynamic listDesig) async {
  XUIDesignManager designMgr = _getDesignManager(fileInfo);
  List listDesign = listDesig;

  for (PropInfo item in listDesign) {
    if (item.value != item.value_orig || item.bind != item.bind_orig) {
      designMgr.listXidChanged.add(item.xid);

      if (item.bind != item.bind_orig)
      {
        designMgr.xuiEngine!.bindingManager.remaneVariable(item.bind_orig, item.bind);
      }

      if (item.variable.startsWith(":"))
      {
        designMgr.xuiEngine!.bindingManager.remaneVariable(item.value_orig, item.value );
      }

      await designMgr.changeProperty(
          item.xid, item.variable, item.value, item.bind);
    }
  }
  fileInfo.mode = "template";

  await _reloadTemplate(fileInfo);

  // // appel la promise
  // String xidProp = (listDesign[0] as PropInfo).xid;
  // doPromiseJS("setDesignProperties", xidProp);
}

void getDesignPropertiesXUI(
    FileDesignInfo fileInfo, String id, String? idslot) async {
  if (idslot == null) {
    idslot = id;
  }
  var designInfo =
      await _getDesignManager(fileInfo).getJSDesignInfo(id, idslot, fileInfo.action);

  var ret = ObjectDesignProperties();
  ret.xid = designInfo.xid;
  ret.xidSlot = designInfo.xidSlot;
  ret.isSlot = id.startsWith(SLOT_PREFIX);
  ret.data = "[" + designInfo.bufData.toString() + "]";
  ret.template = designInfo.bufTemplate.toString();
  ret.path = designInfo.bufPath.toString();

  doPromiseJS("getDesignProperties", ret);
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
  var engine = _getDesignManager(fileInfo).getXUIEngine();
  var info = engine.getSlotInfo(id, idslot);

  var InfoJS = SlotInfoJS();
  if (info != null) {
    InfoJS.docId = info.docId!;
    InfoJS.idRessource = info.idRessource;
    InfoJS.parentXid = info.parentXid!;
    InfoJS.slotname = info.slotname;
    InfoJS.xid = info.xid!;
    DocInfo? doc = engine.docInfo[info.docId];
    if (doc == null) {
      //recherche la doc du parent
      int idx = info.docId!.indexOf(":");
      if (idx > 0) {
        var docId = info.docId!.substring(idx + 1);
        doc = engine.docInfo[docId];
      }
    }
    InfoJS.addRemoveAction = doc?.addRemove;
  }
  return InfoJS;
}

Future addDesignXUI(FileDesignInfo fileInfo, String id, String template,
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
      await _reloadTemplate(fileInfo);
    }
  }
}

///****************************************************************** */

Future deleteDesignXUI(FileDesignInfo fileInfo, String id) async {
  XUIDesignManager designMgr = _getDesignManager(fileInfo);
  SlotInfo info = designMgr.getXUIEngine().getSlotInfo(id, id)!;
  await designMgr.removeDesign(id, null);
  // lance le reload
  designMgr.listXidChanged.add(info.parentXid);
  await _reloadTemplate(fileInfo);
}

void cutDesignXUI(FileDesignInfo fileInfo, String id) async {
  XUIDesignManager designMgr = _getDesignManager(fileInfo);

  SlotInfo info = designMgr.getXUIEngine().getSlotInfo(id, id)!;

  String? lastCopyXid = _getContentCopyZoneID(designMgr);

  if (lastCopyXid != null) {
    // supprime la vielle trashcan
    await designMgr.removeDesign(lastCopyXid, null);
  }

  // ajoute un design a la trashcan
  String slot = "<xui-design xid=\"" + XUI_COPYZONE_SLOT + "\"></xui-design>";
  await addDesignXUI(fileInfo, XUI_COPYZONE_SLOT, slot, false,
      true); //todo ajout direct xuiDesign

  // move id vers la trashcan
  designMgr.moveDesign(id, null, XUI_COPYZONE_SLOT);

  // lance le reload
  designMgr.listXidChanged.add(info.parentXid);
  await _reloadTemplate(fileInfo);
}

void copyDesignXUI(FileDesignInfo fileInfo, String id) async {
  XUIDesignManager designMgr = _getDesignManager(fileInfo);

  String? lastCopyXid = _getContentCopyZoneID(designMgr);

  if (lastCopyXid != null) {
    // supprime la vielle trashcan
    await designMgr.removeDesign(lastCopyXid, null);
  }

  // ajoute un design a la trashcan
  // String slot = "<xui-design xid=\"" + XUI_COPYZONE_SLOT + "\"></xui-design>";
  // await addDesign(fileInfo, XUI_COPYZONE_SLOT, slot, false, true);

  designMgr.addXUIDesignEmpty(XUI_COPYZONE_SLOT);

  // move id vers la trashcan
  designMgr.cloneDesign(id, XUI_COPYZONE_SLOT, null);

  // lance le reload
  designMgr.listXidChanged.add(id);
  await _reloadTemplate(fileInfo);
}

void surroundDesignXUI(FileDesignInfo fileInfo, String id, String template,
    String xidSurround) async {
  XUIDesignManager designMgr = _getDesignManager(fileInfo);

  SlotInfo info = designMgr.getXUIEngine().getSlotInfo(id, id)!;
  var xidParent = info.parentXid!;
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
  await _reloadTemplate(fileInfo);
}

void moveDesignXUI(FileDesignInfo fileInfo, String? id, String idMoveTo) async {
  XUIDesignManager designMgr = _getDesignManager(fileInfo);

  if (id == null) {
    // gestion du move avec clone ( ex : copy, paste)
    id = _getContentCopyZoneID(designMgr);
    designMgr.cloneDesign(id!, idMoveTo, null);
    designMgr.listXidChanged.add(idMoveTo);

    await _reloadTemplate(fileInfo);
  } else {
    // gestion du move (ex : drag)
    designMgr.addXUIDesignEmpty(idMoveTo);
    designMgr.moveDesign(id, null, idMoveTo);
    designMgr.listXidChanged.add(id);
    designMgr.listXidChanged.add(idMoveTo);

    await _reloadTemplate(fileInfo);
  }
}

/// change les enfant avec le nb (ex: tab, grid, etc...)
void changeNbChildXUI(
    FileDesignInfo fileInfo, String idSlot, String action) async {
  var designManager = _getDesignManager(fileInfo);
  SlotInfo infoSlot = designManager.getXUIEngine().getSlotInfo(idSlot, idSlot)!;
  SlotInfo infoContainer = designManager
      .getXUIEngine()
      .getSlotInfo(infoSlot.parentXid!, infoSlot.parentXid!)!;

  var nbItem =
      int.parse(infoContainer.elementHTML!.propertiesXUI!["nb"]!.content);

  print(
      "changeChild " + action + " " + idSlot + " nbItem " + nbItem.toString());

  if (action != "delete") {
    // ajoute un slot en incrementant le nb
    await designManager.changeProperty(
        infoSlot.parentXid!, "nb", (nbItem + 1).toString(), null);
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
      return await deleteDesignXUI(fileInfo, infoSlot.parentXid!);
    }

    // retire un slot
    await designManager.changeProperty(
        infoSlot.parentXid!, "nb", (nbItem - 1).toString(), null);
  }

  designManager.listXidChanged.add(infoSlot.parentXid);
  await _reloadTemplate(fileInfo);
}

Future _doMoveChildByIdx(String suffix, int i, int idst,
    XUIDesignManager designManager, FileDesignInfo fileInfo) async {
  var idSlotToMove = suffix + i.toString();
  var idSlotToDest = suffix + idst.toString();
  //SlotInfo infoSlot = designManager.xuiEngine.getSlotInfo(idSlotToMove, idSlotToMove);
  //
  var listDesign = designManager.getXUIEngine().xuiFile.designs[idSlotToMove];
  if (listDesign != null) {
    var xuiDesign =
        listDesign.sort(designManager.getXUIEngine().xuiFile.context).first;
    var id = ((xuiDesign.elemXUI.children!.first) as XUIElementXUI).xid!;
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

/// retourne le code html d'un xui (pour les reloader)
void getHtmlFromXUI(FileDesignInfo fileInfo, String idPromise) async {
  var ctx = XUIContext(fileInfo.mode);
  ctx.setCause("getHtmlFromXUI");
  var designMgr = _getDesignManager(fileInfo);
  var html;

  if (fileInfo.partXID == null) {
    html = await designMgr.getHtml(ctx, fileInfo.file, fileInfo.xid);
  } else {
    SlotInfo info = designMgr
        .getXUIEngine()
        .getSlotInfo(fileInfo.partXID!, fileInfo.partXID!)!;
    //print("part = " + info.elementHTML.tag);
    var bufferHtml = XUIHtmlBuffer();
    info.elementHTML!.processPhase3(designMgr.getXUIEngine(), bufferHtml);
    html = bufferHtml.html.toString();
  }

  doPromiseJS(idPromise, html);
  //context["\$xui"].callMethod("doPromiseJS", [idPromise, html]);
}

Future _reloadTemplate(FileDesignInfo fileInfo) async {
  // if (fileInfo.jsonBinding!=null)
  //   print("jsonBinding="+fileInfo.jsonBinding);

  var designMgr = _getDesignManager(fileInfo);

  List listReloader = [];
  designMgr.listXidChanged.forEach((key) {
    var reloaderId = designMgr.getXUIEngine().getReloaderID(key);

    if (XUIConfigManager.verboseReloader) {
      XUIConfigManager.printc("****** reloader : changed xid  " +
          key +
          " => reloader id " +
          (reloaderId ?? "?"));
    }

    if (reloaderId != null) {
      listReloader.add(reloaderId);
    }
  });

  designMgr.listXidChanged.clear();
 
  var ctx = XUIContext(fileInfo.mode);
  ctx.setCause("reloadTemplate");
  var options = Options(mode: fileInfo.mode);
  if (listReloader.isEmpty) {
    if (XUIConfigManager.verboseReloader) {
      XUIConfigManager.printc("****** reloader next: all " + ctx.mode);
    }
    var str = await designMgr.getHtml(ctx, fileInfo.file, fileInfo.xid);
    options.html = str!;
  } else {
    await designMgr.initHtml(ctx, fileInfo.file, fileInfo.xid);
    options.listReloader = listReloader;
  }

  String objXui = JsonEncoder.withIndent('   ') //null
      .convert(ObjectWriter().toObjects(designMgr.getXUIEngine().xuiFile));

  options.xuidata = objXui;
  options.xuifile = HTMLWriter().toHTMLString(designMgr.getXUIEngine().xuiFile);
  options.action = fileInfo.action;

  //options.binding = designMgr.getXUIEngine().getBindingInfo();
  options.treeSlot = new XUISlotTreeManager(designMgr.getXUIEngine()).getSlotTree();

  changePageJS(options);
}

dynamic getActionsXUI(
    FileDesignInfo fileInfo, String id, String idSlot, String action) {
  print("-------------- getActionsXUI ----------------   " + action);

  var ctx = XUIContext(MODE_DESIGN);
  var designManager = _getDesignManager(fileInfo);

  return designManager.getActionsPopup(ctx, id, idSlot, action);
}

dynamic getEventMethodsXUI(FileDesignInfo fileInfo) {
  print("-------------- getEventMethodsXUI ----------------   " + fileInfo.fileID);
  var designManager = _getDesignManager(fileInfo);
  return designManager.getXUIEngine().bindingManager.getEventMethodsXUI();
}

void main() async {
  _refreshPageXUI = allowInterop(refreshPageXUI);
  _addDesignXUI = allowInterop(addDesignXUI);
  _cutDesignXUI = allowInterop(cutDesignXUI);
  _copyDesignXUI = allowInterop(copyDesignXUI);
  _surroundDesignXUI = allowInterop(surroundDesignXUI);
  _moveDesignXUI = allowInterop(moveDesignXUI);

  _changeNbChildXUI = allowInterop(changeNbChildXUI);
  _getInfoXUI = allowInterop(getInfoXUI);
  _getDesignPropertiesXUI = allowInterop(getDesignPropertiesXUI);
  _saveDesignPropertiesXUI = allowInterop(saveDesignPropertiesXUI);
  _getComponentsXUI = allowInterop(getComponentsXUI);
  _getHtmlFromXUI = allowInterop(getHtmlFromXUI);
  _deleteDesignXUI = allowInterop(deleteDesignXUI);
  _initPageXUI = allowInterop(initPageXUI);
  _getActionsXUI = allowInterop(getActionsXUI);
  _getEventMethodsXUI = allowInterop(getEventMethodsXUI);
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

      XUIConfigManager.printc(
          "initEngine with localStorage " + name + " v" + v.toString());

      //print(db);
      var saveDb = json.decode(db!); //loadYaml(db);

      for (var aDesign in saveDb["design"]) {
        designManager.getXUIEngine().xuiFile.addObjectDesign(aDesign);
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

String? _getContentCopyZoneID(XUIDesignManager designMgr) {
  SlotInfo infoTrash = designMgr
      .getXUIEngine()
      .getSlotInfo(XUI_COPYZONE_SLOT, XUI_COPYZONE_SLOT)!;

  XUIElementHTML? contentTrash =
      infoTrash.elementHTML?.children?.first as XUIElementHTML?;
  var lastDeleteXid = contentTrash?.originElemXUI?.xid;
  return lastDeleteXid;
}
