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
import 'core/parser/ObjectReader.dart';
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
    void Function(FileDesignInfo, String, String, String, String?) f);

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
    dynamic Function(FileDesignInfo, String) f);


@JS('getPropertieFromXUI')
external set _getPropertieFromXUI(
    void Function(FileDesignInfo, String, String) f);

/// retourne les properties
@JS('getPropertiesXUI')
external set _getPropertiesXUI(
    void Function(FileDesignInfo, String, String, int) f);

@JS('getDesignPropertiesXUI')
external set _getDesignPropertiesXUI(
    void Function(FileDesignInfo, String, String) f);

/// change les properties
@JS('saveDesignPropertiesXUI')
external set _saveDesignPropertiesXUI(
    dynamic Function(FileDesignInfo, dynamic) f);

/// change les properties
@JS('getJsonValidatorXUI')
external set _getJsonValidatorXUI(
    dynamic Function(FileDesignInfo) f);

///------------------------------------------------------------------
Future initPageXUI(FileDesignInfo fileInfo) async {
  XUIConfigManager.printc("-------------- start initPage xui ----------------");
  XUIDesignManager.removeDesignManager(fileInfo);
  var ctx = XUIContext(fileInfo.mode);
  var designManager = _getDesignManager(fileInfo);

  await _initStoreVersion(designManager, fileInfo, ctx);

  String? str = await designManager.getHtml(ctx, fileInfo.file, fileInfo.xid);

  var options = Options(mode: fileInfo.mode);

  options.treeSlot = new XUISlotTreeManager(designManager.getXUIEngine()).getSlotTree();

  XUIProperty? propConfig =  designManager.getXUIEngine().getXUIPropertyFromDesign("root", "appConfig");
  options.appConfig=propConfig?.content?.toString() ?? "";
  options.action = XUIConfigManager.reloaderEnable?"":"reloaderDisable";
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
    // affecte le text de l'editor uniquement
    if (fileInfo.saveStoreModuleNamespace!="")
    {
      var newBinding = generateApplicationStateJS(fileInfo.saveStoreModuleNamespace, "", ""); 
      var designManager = _getDesignManager(fileInfo);
      await designManager.changeProperty("root", PROP_BIND_PREFIX+"_"+fileInfo.saveStoreModuleNamespace, newBinding, MODE_SET_PROP_NODOC);
    }
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

      if (item.bind != item.bind_orig && item.bind!=null && item.bind_orig!=null)
      {
        designMgr.xuiEngine!.bindingManager.remaneVariable(item.bind_orig!, item.bind!);
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
  ret.path = designInfo.listPath;
  ret.pathChildren = designInfo.listChildPath;
  ret.pathConditional = designInfo.listConditionalPath;

  doPromiseJS("getDesignProperties", ret);
}

dynamic getPropertieFromXUI(FileDesignInfo fileInfo, String id, String variable) {
     var prop = _getDesignManager(fileInfo).getXUIEngine().getXUIPropertyFromDesign(id, variable);
     return prop==null?null : prop.content;
}

dynamic getPropertiesXUI(FileDesignInfo fileInfo, String id, String? idslot, int deep) {
  if (idslot == null) {
    idslot = id;
  }
  var designInfo = _getDesignManager(fileInfo).getJSDesignValue(id, idslot, deep);

  var ret = ObjectDesignProperties();
  ret.xid = designInfo.xid;
  ret.xidSlot = designInfo.xidSlot;
  ret.isSlot = id.startsWith(SLOT_PREFIX);
  ret.data = "[" + designInfo.bufData.toString() + "]";
  return ret;
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
 // vueParamJS.path = designInfo.bufPath.toString();

  return vueParamJS;
}

/// retourne les info d'un xid
dynamic getInfoXUI(FileDesignInfo fileInfo, String id, String idslot) {
  var engine = _getDesignManager(fileInfo).getXUIEngine();

  if (idslot.startsWith(SLOT_PREFIX))
  {
     idslot = idslot.substring(SLOT_PREFIX.length);
  }
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
    String xidSurround, String? slotExt) async {
  XUIDesignManager designMgr = _getDesignManager(fileInfo);

  SlotInfo info = designMgr.getXUIEngine().getSlotInfo(id, id)!;
  var xidParent = info.parentXid!;
  // ajoute un design au tempory
  designMgr.addXUIDesignEmpty(XUI_TEMPORARY_SLOT);

  // move id vers la tempory
  designMgr.moveDesign(id, null, XUI_TEMPORARY_SLOT);

  await addDesignXUI(fileInfo, xidParent, template, false, true);

  String targetXid = xidSurround + (slotExt??"-col-0");
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
    var xuiDesign = listDesign.sort(designManager.getXUIEngine().xuiFile.context).first;

    if (xuiDesign.elemXUI.children==null || xuiDesign.elemXUI.children!.length==0)
    {
      return;
    }

    var id = ((xuiDesign.elemXUI.children!.first) as XUIElementXUI).xid!;
    print("move => " + id + " to " + idSlotToDest);
    // inspect(xuiDesign.elemXUI);

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
    if (designMgr.getXUIEngine().xuiFile.context.mode!=ctx.mode && ctx.mode==MODE_PREVIEW) {
      // reinit pour le recup de code source de EditorCmp
      ctx.setCause("reloadTemplate");
      ctx.mode=MODE_FINAL;
      ctx.forPreview = true;
     // print("reload getHtmlFromXUI " + ctx.mode);
      await designMgr.initHtml(ctx, fileInfo.file, fileInfo.xid);

    }


    SlotInfo? info = designMgr
        .getXUIEngine()
        .getSlotInfo(fileInfo.partXID!, fileInfo.partXID!);

    if (info==null)
    {
      print("error part = " + fileInfo.partXID!);
      html="";
    }
    else {
      designMgr.getXUIEngine().xuiFile.context=ctx;
      var bufferHtml = XUIHtmlBuffer();
      info.elementHTML!.processPhase3(designMgr.getXUIEngine(), bufferHtml);
      html = bufferHtml.html.toString();
    }

  }

  doPromiseJS(idPromise, html);
}

Future _reloadTemplate(FileDesignInfo fileInfo) async {

  var designMgr = _getDesignManager(fileInfo);

  List listReloader = [];
  designMgr.listXidChanged.forEach((key) {
    var reloaderId = designMgr.getXUIEngine().getReloaderID(key, fileInfo);

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

  String objXui = JsonEncoder.withIndent(' ') //null
      .convert(ObjectWriter().toObjects(designMgr.getXUIEngine().xuiFile));

  options.xuidata = objXui;
  options.xuifile = HTMLWriter().toHTMLString(designMgr.getXUIEngine().xuiFile);
  options.action = fileInfo.action;

  //options.binding = designMgr.getXUIEngine().getBindingInfo();
  options.treeSlot = new XUISlotTreeManager(designMgr.getXUIEngine()).getSlotTree();

  if (ctx.returnAction=="doReloadAllPage")
    options.mode="templateAll";
  
  changePageJS(options);
}

dynamic getActionsXUI(
    FileDesignInfo fileInfo, String id, String idSlot, String action) {
  print("-------------- getActionsXUI ----------------   " + action);

  var designManager = _getDesignManager(fileInfo);

  inspect(designManager);

  return designManager.getActionsPopup(fileInfo, id, idSlot, action);
}

dynamic getEventMethodsXUI(FileDesignInfo fileInfo, String namespace) {
  print("-------------- getEventMethodsXUI ----------------   " + fileInfo.fileID);
  var designManager = _getDesignManager(fileInfo);
  return designManager.getXUIEngine().bindingManager.getEventMethodsXUI(namespace);
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
  _getPropertiesXUI = allowInterop(getPropertiesXUI);
  _getPropertieFromXUI = allowInterop(getPropertieFromXUI);
  _getDesignPropertiesXUI = allowInterop(getDesignPropertiesXUI);
  _saveDesignPropertiesXUI = allowInterop(saveDesignPropertiesXUI);
  _getComponentsXUI = allowInterop(getComponentsXUI);
  _getHtmlFromXUI = allowInterop(getHtmlFromXUI);
  _deleteDesignXUI = allowInterop(deleteDesignXUI);
  _initPageXUI = allowInterop(initPageXUI);
  _getActionsXUI = allowInterop(getActionsXUI);
  _getEventMethodsXUI = allowInterop(getEventMethodsXUI);
  _getJsonValidatorXUI = allowInterop(getJsonValidatorXUI);
}


String getJsonValidatorXUI(FileDesignInfo fileInfo) {
  XUIDesignManager designManager = XUIDesignManager.getDesignManager(fileInfo);

  StringBuffer buf = StringBuffer();
  buf.write("\n\$xui.jsonvalidator={");
  designManager.xuiEngine!.bindingManager.afterJsonValidator.forEach((key, value) {
    buf.write("'"+key+"': (ctx)=> {"+value.toString()+"},");
  });
  buf.write("};");


  //engine.bindingManager.validatorInfo[xid]=XUIBinding(cmp.elemXUI.xid!, "","", xid);
  designManager.xuiEngine!.bindingManager.validatorInfo.forEach((key, value) {
    List<XUIBinding> listBinding = [];
    designManager.xuiEngine!.bindingManager.bindingInfo.forEach((k, valueBinding) {
        if (valueBinding.xid==value.xid)
        {
          listBinding.add(valueBinding);
        }
    });
    listBinding.forEach((bind) { 
        buf.write("\n\$xui.jsonvalidator['"+value.propName+"']( {jsonState, prop:'"+bind.propName+"', attr:'"+bind.attr+"', xid:'"+ bind.xid+"'} );");
    });
  });

  return buf.toString();
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

    var fileName =fileInfo.file;
    if (v >= 0) {
    // force une page vide pour pouvoir tous surcharger
      fileName = 'app/frame0Empty.html'; 
    }
    
    await designManager.initEngine(fileName, ctx);

    if (v >= 0) {
      var db = window.localStorage['xui_data_' + name + '_' + v.toString()];

      XUIConfigManager.printc(
          "initEngine with localStorage " + name + " v" + v.toString());

      var saveDb = json.decode(db!); //loadYaml(db);

      await ObjectReader.addObject(saveDb, designManager.xuiEngine!);

      designManager.xuiEngine!.xuiFile.generateDocumentation(designManager.xuiEngine!);

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
