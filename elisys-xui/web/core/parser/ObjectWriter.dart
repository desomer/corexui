import '../XUIEngine.dart';
import '../XUIFactory.dart';
import '../element/XUIElement.dart';
import '../element/XUIProperty.dart';

class ObjectWriter {
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
          item.elemXUI.propertiesXUI!.forEach((k, v) {
            if (v is XUIPropertyBinding) {
              prop.add({
                "id": k,
                "val": v.content.toString(),
                "binding": v.binding!.trim()
              });
            } else {
              prop.add({"id": k, "val": v.content.toString()});
            }
          });

          des["props"] = prop;
        }

        var children = item.elemXUI.children;

        if (children != null) {
          var childrenObj = [];
          children.forEach((elem) {
            XUIElementXUI aChild = elem as XUIElementXUI;
            bool isText = aChild is XUIElementText;
            if (!isText) {
              childrenObj.add({"tag": aChild.tag, "xid": aChild.xid});
            }
          });

          if (childrenObj.isNotEmpty) {
            des["children"] = childrenObj;
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
