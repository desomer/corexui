@JS("\$xui")
library xuiapp;

import 'package:js/js.dart';

///------------------------- methode XUI vers JS -----------------------------

@JS()
external void loadPageJS(obj, bind);

@JS()
external void changePageJS(obj);

@JS()
external void doPromiseJS(idPromise, ret);

@JS()
external String generateApplicationStateJS(template, last);

@JS()
external String generateApplicationStoreJS(state, action);


@JS()
@anonymous
class FileDesignInfo {
  external String get action;
  external set action(String action);
  external String get file;
  external set file(String file);

  external String get fileID;
  external set fileID(String fileID);

  external String get mode;
  external set mode(String mode);
  external String? get partXID;        
  external set partXID(String? part);
  external String get xid;
  external set xid(String xid);

  external String get jsonBinding;
  external set jsonBinding(String json);

}

@JS()
@anonymous
class ObjectAction {
  external factory ObjectAction(
      {String xid, String action, String type, String icon, String title});
  external String get action;
  external set action(String action);
  external String get type;
  external set type(String type);
  external String get icon;
  external set icon(String icon);
  external String get title;
  external set title(String title);
  external String get xid;
  external set xid(String xid);
}

@JS()
@anonymous
class PropInfo {
  external bool get exist;
  external String get value;
  external String get value_orig;
  external String get variable;
  external String get xid;
  external String? get bind;
  external String? get bind_orig;
}

@JS()
@anonymous
class ObjectDesignProperties {
  external String get xid;
  external set xid(String xid);
  external String get xidSlot;
  external set xidSlot(String xid);
  external bool get isSlot;
  external set isSlot(bool xid);

  external String get data;
  external set data(String xid);

  external String get template;
  external set template(String xid);

  // external String get path;
  // external set path(String xid);
  external List get path;
  external set path(List tree);
}


@JS()
@anonymous
class Options {
  external factory Options({String mode, dynamic html, dynamic xuidata});
  external String get action;
  external set action(String action);
  external String get html;                  //code Html
  external set html(String html);
  external List get listReloader;
  external set listReloader(List listReloader);
  external String get mode;
  external set mode(String mode);
  external String get xuidata;             //code JSON
  external set xuidata(String xuidata);
  external String get xuifile;              //code XML XUI
  external set xuifile(String xuifile);
  // external List get binding;
  // external set binding(List binding);
  external List get treeSlot;
  external set treeSlot(List tree);
  external String get appConfig;
  external set appConfig(String data);
}

@JS()
@anonymous
class BindObj {
  external String get attr;
  external set attr(String attr);
  external dynamic get val;
  external set val(dynamic val);
}

@JS()
@anonymous
class XUIBindingEvent {
   external String xid;
   external String eventName;
   external String name;
   external String? code; 

   external factory XUIBindingEvent({String xid, String eventName, String name});
}

@JS()
@anonymous
class TreeSlot {
  external String get id;
  external set id(String id);
  external String get name;
  external set name(String name);
  external List? get children;
  external set children(List? name);
  external bool get isSlot;
  external set isSlot(bool iss);
  external String get icon;
  external set icon(String ic);
  external String? get toPath;
  external set toPath(String? path);
  external TreeSlot get parent;
  external set parent(TreeSlot p);
}

@JS()
@anonymous
class SlotInfoJS {
  external String? get addRemoveAction;
  external set addRemoveAction(String? addRemoveAction);
  external String get docId;
  external set docId(String docId);
  external String? get idRessource;
  external set idRessource(String? idRessource);
  external String get parentXid;
  external set parentXid(String parentXid);
  external String? get slotname;
  external set slotname(String? slotname);
  external String get xid;
  external set xid(String xid);
}

@JS()
@anonymous
class VueParamJS {
  external String get data;
  external set data(String xid);
  external bool get isSlot;
  external set isSlot(bool isSlot);
  external List<TreeSlot> get path;
  external set path(List<TreeSlot> path);
  external String get target;

  external set target(String xid);
  external String get template;
  external set template(String xid);
  external String get xid;
  external set xid(String xid);
  external String get xidSlot;
  external set xidSlot(String xidSlot);
}

