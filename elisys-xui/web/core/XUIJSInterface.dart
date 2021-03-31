@JS("\$xui")
library xuiapp;

import 'package:js/js.dart';

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
  external String get part;
  external set part(String part);
  external String get xid;
  external set xid(String xid);
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
class ObjectDesign {
  external bool get exist;
  external String get value;
  external String get value_orig;
  external String get variable;
  external String get xid;
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

  external String get path;
  external set path(String xid);
}


@JS()
@anonymous
class Options {
  external factory Options({String mode, dynamic html, dynamic xuidata});
  external String get action;
  external set action(String action);
  external String get html;
  external set html(String html);
  external List get listReloader;
  external set listReloader(List listReloader);
  external String get mode;
  external set mode(String mode);
  external String get xuidata;
  external set xuidata(String xuidata);
  external String get xuifile;
  external set xuifile(String xuifile);
  external List get binding;
  external set binding(List binding);
}

@JS()
@anonymous
class BindObj {
  external String get attr;
  external set attr(String attr);
  external String get val;
  external set val(String val);
}

@JS()
@anonymous
class SlotInfoJS {
  external String get addRemoveAction;
  external set addRemoveAction(String addRemoveAction);
  external String get docId;
  external set docId(String docId);
  external String get idRessource;
  external set idRessource(String idRessource);
  external String get parentXid;
  external set parentXid(String parentXid);
  external String get slotname;
  external set slotname(String slotname);
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
  external String get path;
  external set path(String path);
  external String get target;

  external set target(String xid);
  external String get template;
  external set template(String xid);
  external String get xid;
  external set xid(String xid);
  external String get xidSlot;
  external set xidSlot(String xidSlot);
}
