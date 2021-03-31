

import '../XUIEngine.dart';
import '../XUIFactory.dart';
import '../element/XUIElement.dart';
import '../element/XUIProperty.dart';

class ObjectWriter
{

  dynamic toObjects(XUIResource xuiFile) {
    var ret = {};
    var import = [];

    for (var anImport in xuiFile.listImport) {
      import.add({"name": anImport.reader.id});
    }

    var design = [];
    xuiFile.designs.forEach((k, v) {
      for (XUIDesign item in v.list) {
        var des = {};
        des["xid"] = item.elemXUI.xid;

        if (item.elemXUI.propertiesXUI != null) {
          var prop = [];
          item.elemXUI.propertiesXUI.forEach((k, v) {
            if (v is XUIPropertyBinding) {
              prop.add({"id": k, "val": v.content.toString(), "binding": v.binding.trim()});
            } else {
              prop.add({"id": k, "val": v.content.toString()});
            }
          });

          des["props"] = prop;
        }

        if (item.elemXUI.children != null) {
          var children = [];
          for (XUIElementXUI aChild in item.elemXUI.children) {
            if (aChild is! XUIElementText) {
              children.add({"tag": aChild.tag, "xid": aChild.xid});
            }
          }
          if (children.isNotEmpty) {
            des["children"] = children;
          }
        }

        design.add(des);
      }
    });

    var compo = [];
    xuiFile.components.forEach((k, v) {
      for (XUIComponent item in v.list) {
        if (item.elemXUI.idRessource != null) {
          var des = {};
          des["xid"] = item.elemXUI.xid;
          des["tag"] = item.elemXUI.tag;
          //des["mode"] = item.mode;
          compo.add(des);
        }
      }
    });

    ret["import"] = import;
    ret["design"] = design;
    ret["component"] = compo;
    return ret;
  }

}