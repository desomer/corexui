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

  external void set target(String xid);
  external void set template(String xid);
  external void set data(String xid);
}
