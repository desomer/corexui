@JS("\$xui")
library xuiapp;

import 'package:js/js.dart';

@JS()
@anonymous
class SlotInfoJS {
  external String get xid;
  external String get parentXid;
  external String get slotname;
  external String get docId;
  external String get idRessource;
  external set xid(String xid);
  external set parentXid(String xid);
  external set slotname(String xid);
  external set docId(String xid);
  external set idRessource(String xid);
}

@JS()
@anonymous
class VueParamJS {
  external String get target;
  external String get template;
  external String get data;
  external String get path;
  external String get xid;
  external String get xidSlot;
  external bool get isSlot;

  external set target(String xid);
  external set template(String xid);
  external set data(String xid);
  external set path(String path);
  external set xid(String xid);
  external set xidSlot(String xidSlot);
  external set isSlot(bool isSlot);
}

@JS()
@anonymous
class Options {
  external String get mode;
  external String get html;
  external String get yaml;
  external List get listReloader;
  external String get action;
  external set html(String html);
  external set mode(String mode);
  external set yaml(String yaml);
  external set listReloader(List listReloader);
  external set action(String action);
  external factory Options({String mode, dynamic html, dynamic yaml});
}

@JS()
@anonymous
class ObjectDesign {
  external String get xid;
  external String get variable;
  external String get value;
  external String get value_orig;
  external bool get exist;
}

@JS()
@anonymous
class FileDesignInfo {
  external String get file;
  external String get xid;
  external String get mode; 
  external String get action; 
  external String get part;

  external set file(String file);
  external set xid(String xid);
  external set mode(String mode);
  external set action(String action);
  external set part(String part);
}
