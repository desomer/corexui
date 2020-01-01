@JS("xui")
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
  external void set xid(String xid);
  external void set parentXid(String xid);
  external void set slotname(String xid);
  external void set docId(String xid);
  external void set idRessource(String xid);
}

@JS()
@anonymous
class VueParamJS {
  external String get target;
  external String get template;
  external String get data;
  external String get path;

  external void set target(String xid);
  external void set template(String xid);
  external void set data(String xid);
  external void set path(String path);
}

@JS()
@anonymous
class Options {
  external String get mode;
  external String get html;
  external void set html(String html);
  external void set mode(String mode);
  external factory Options({String mode, dynamic html});
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
