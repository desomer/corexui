import '../XUIEngine.dart';
import '../XUIFactory.dart';
import '../element/XUIElement.dart';

class HTMLWriter {
  String toHTMLString(XUIResource xuiFile) {
    XUIHtmlBuffer buf = XUIHtmlBuffer();
    buf.html.writeln('<xui-factory version="1.0">');
    buf.tab(1);

    for (var anImport in xuiFile.listImport) {
      buf.addTab();
      buf.html.writeln(
          '<xui-import xui-path="${anImport.reader.id}"></xui-import>');
    }

    buf.html.writeln('');

    xuiFile.components.forEach((k, v) {
      for (XUIComponent item in v.list) {
        if (item.elemXUI.idRessource != null) {
          buf.addTab();
          buf.html.writeln('<${item.elemXUI.tag} xid="${item.elemXUI.xid}"></${item.elemXUI.tag}>');
          buf.html.writeln('');
        }
      }
    });

    xuiFile.designs.forEach((k, v) {
      for (XUIDesign item in v.list) {
        buf.addTab();
        buf.html.writeln('<xui-design xid="${item.elemXUI.xid}">');
        buf.tab(1);


        if (item.elemXUI.propertiesXUI != null) {
          item.elemXUI.propertiesXUI.forEach((k, v) {
             buf.addTab();
             buf.html.writeln('<xui-prop id="${k}" val="${v.content.toString()}"></xui-prop>');
          });
        }

        if (item.elemXUI.children != null) {
          for (XUIElementXUI aChild in item.elemXUI.children) {
            if (aChild is! XUIElementText) {
              buf.addTab();
              buf.html.writeln('<${aChild.tag} xid="${aChild.xid}"></${aChild.tag}>');
            }
          }
        }

        buf.tab(-1);
        buf.addTab();
        buf.html.writeln('</xui-design>');
        buf.html.writeln('');



      }
    });

        

    buf.tab(-1);
    buf.html.writeln('</xui-factory>');

    return buf.html.toString();

    // var design = [];
    // designs.forEach((k, v) {
    //   for (XUIDesign item in v.list) {
    //     var des = {};
    //     des["xid"] = item.elemXUI.xid;

    //     if (item.elemXUI.propertiesXUI != null) {
    //       var prop = [];
    //       item.elemXUI.propertiesXUI.forEach((k, v) {
    //         prop.add({"id": k, "val": v.content.toString()});
    //       });

    //       des["props"] = prop;
    //     }

    //     if (item.elemXUI.children != null) {
    //       var children = [];
    //       for (XUIElementXUI aChild in item.elemXUI.children) {
    //         if (aChild is! XUIElementText) {
    //           children.add({"tag": aChild.tag, "xid": aChild.xid});
    //         }
    //       }
    //       if (children.isNotEmpty) {
    //         des["children"] = children;
    //       }
    //     }

    //     design.add(des);
    //   }
    // });

    // var compo = [];
    // components.forEach((k, v) {
    //   for (XUIComponent item in v.list) {
    //     if (item.elemXUI.idRessource != null) {
    //       var des = {};
    //       des["xid"] = item.elemXUI.xid;
    //       des["tag"] = item.elemXUI.tag;
    //       //des["mode"] = item.mode;
    //       compo.add(des);
    //     }
    //   }
    // });
  }
}
