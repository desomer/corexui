import 'dart:collection';

import 'XUIEngine.dart' as Const;
import 'XUIEngine.dart';
import 'element/XUIElement.dart';
import 'element/XUIProperty.dart';

/************************************************************* */
class XUIHtmlBuffer {
  var html = StringBuffer();
  int idxTab = 0;

  addTab() {
    for (var i = 0; i < idxTab; i++) {
      html.write("   ");
    }
  }

  tab(int i) {
    idxTab += i;
  }
}

/************************************************************* */
class XUIComponent extends XUIModel {
  XUIComponent(e, m) : super(e, m);
}

class XUIDesign extends XUIModel {
  XUIDesign(e, m) : super(e, m);
}

class XUIChild extends XUIModel {
  XUIChild(e, m) : super(e, m);
}

/************************************************************** */
/**
 * gestion des designs ou des components
 */
class XUIModel implements Comparable<XUIModel> {
  int priority = 0; // gestion de la priorité d'application
  XUIElementXUI elemXUI;
  String mode; // final, template, design, etc...

  XUIModel(this.elemXUI, this.mode);

  Future processPhase1(XUIResource xuifile, XUIElementHTML elemHtml) async {
    var tag = elemXUI.tag;

    /********** AFFECTE LES INFO POUR LE DESIGNER *************/
    if (this is XUIComponent)
      elemHtml.implementBy ??= []..add(this);
    else if (this is XUIDesign) elemHtml.designBy ??= []..add(this);

    /*********** EXECUTE LES NATIVES ********/
    if (elemXUI is XUIElementNative) {
      XUIModel model = await (elemXUI as XUIElementNative)
          .doProcessPhase1(xuifile, elemHtml);

      await model.processPhase1(xuifile, elemHtml); // lance le nouveau modele

      return Future.value();
    }
    /*****************************************************************/
    if (tag != null) elemHtml.tag = tag;

    // properties
    processAttributes(elemHtml);

    // properties
    processProperties(elemHtml, xuifile);

    // lance les children
    await processChildren(elemHtml, xuifile);

    // calcul le xid  (ex : __parentxid__ , __idx__)
    var xidCal = calculateProp(elemXUI.xid, elemHtml);

    // lance les design (pour affectation property utilise)
    await processDesign(xidCal, xuifile, elemHtml);

    // lance implementation xui si affecter par le design (ex: remplace un slot par un div)
    await processComponent(xuifile, elemHtml);

    // affecte les xid uniquement si child (pas design ni component)
    if (elemXUI.xid != null && xuifile.context.mode != MODE_FINAL) {
      elemHtml.attributes ??= HashMap<String, XUIProperty>();
      if (this is! XUIComponent && this is! XUIDesign) {
        elemHtml.attributes["data-xid"] = XUIProperty(xidCal);
      }
    }

    return Future.value();
  }

  Future processComponent(
      Const.XUIResource xuifile, XUIElementHTML elemHtml) async {
    if (elemXUI.tag != null /*&& (elem.tag != tag || this is! XUIComponent)*/) {
      var cmp = xuifile.searchComponent(elemXUI.tag);

      if (cmp != null) {
        for (var item in cmp.sort(xuifile.context)) {
          await item.processPhase1(xuifile, elemHtml);
        }
      }
    }
  }

  Future processDesign(
      String xid, Const.XUIResource xuifile, XUIElementHTML elemHtml) async {
    if (xid != null && this is! XUIDesign) {
      var dico = xuifile.searchDesign(xid);

      if (dico != null) {
        for (var item in dico.sort(xuifile.context)) {
          await item.processPhase1(xuifile, elemHtml);
        }
      }
    }
  }

  String calculateProp(String prop, XUIElementHTML elemHtml) {
    if (prop != null) {
      StringBuffer buf = StringBuffer(prop);
      XUIProperty.parse(buf, (String tag) {
        var ret = elemHtml.searchPropertyXUI(tag);
        return ret != null ? ret : "[" + tag + "]";
      });
      prop = buf.toString();
    }
    return prop;
  }

  Future processChildren(XUIElementHTML elemHtml, XUIResource xuifile) async {
    /**************** FOR  *****************/
    int nb = 1;
    String varIdx = null;
    if (elemXUI?.propertiesXUI != null) {
      XUIProperty xuifor = elemHtml.propertiesXUI["for"];
      if (xuifor != null) {
        varIdx = xuifor.content.toString();
        nb =
            int.parse(elemHtml.propertiesXUI["nb"]?.content?.toString() ?? "1");
      }
    }
    /****************************************/

    if (elemXUI.children != null) {
      for (var i = 0; i < nb; i++) {
        for (var item in elemXUI.children) {
          if (varIdx != null) {
            item.propertiesXUI ??= HashMap<String, XUIProperty>();
            item.propertiesXUI[varIdx] = XUIProperty(i.toString());
            item.propertiesXUI["parent-xid"] =
                XUIProperty(calculateProp(elemHtml.origin.xid, elemHtml));
          }
          await doChild(item, elemHtml, xuifile);
        }
      }
    }
    return Future.value();
  }

  Future doChild(childXUI, XUIElementHTML elemHtml, xuifile) async {
    if (childXUI is XUIElementXUI) {
      var childHtml;

      if (childXUI is XUIElementText) {
        childHtml = XUIElementHTMLText();
        childHtml.content = childXUI.content;
        childHtml.parent = elemHtml;
        childHtml.origin = childXUI;
      } else {
        childHtml = XUIElementHTML();
        childHtml.parent = elemHtml;
        childHtml.origin = childXUI;

        var model = XUIChild(childXUI, MODE_ALL);
        await model.processPhase1(xuifile, childHtml);
      }

      elemHtml.children ??= [];

      return Future.sync(() => elemHtml.children.add(childHtml));
    }
  }

  void processAttributes(XUIElementHTML elemHtml) {
    if (elemXUI.attributes != null) {
      elemHtml.attributes ??= HashMap<String, XUIProperty>();
      elemXUI.attributes.entries.forEach((f) {
        String v = f.value.content;

        if (f.key.toLowerCase() == "style") {
          // complete les styles
          XUIProperty style = elemHtml.attributes[f.key];
          completeAttribut(style, elemHtml, f, v, ";");
        } else if (f.key.toLowerCase() == "class") {
          // complete les classes
          XUIProperty classe = elemHtml.attributes[f.key];
          completeAttribut(classe, elemHtml, f, v, " ");
        } else
          elemHtml.attributes[f.key] = XUIProperty(v);
      });
    }
  }

  void completeAttribut(XUIProperty style, XUIElementHTML elemHtml,
      MapEntry<String, XUIProperty> f, String v, String sep) {
    if (style == null)
      elemHtml.attributes[f.key] = XUIProperty(v);
    else {
      elemHtml.attributes[f.key].content += sep + v;
    }
  }

  void processProperties(XUIElementHTML elemHtml, XUIResource xuifile) {
    if (elemXUI.propertiesXUI != null) {
      elemXUI.propertiesXUI.entries.forEach((prop) {
        elemHtml.propertiesXUI ??= HashMap<String, XUIProperty>();

        if (prop.key.toLowerCase() != Const.ATTR_XID) {
          // n'affecte pas le XID car gerer par attribut xid
          elemHtml.propertiesXUI[prop.key] = prop.value;
        }

        // if (prop.key.toLowerCase() == Const.ATTR_SLOT_NAME &&
        //     xuifile.context.mode != MODE_FINAL) {
        //   // affecte le nom du slot en data-
        //   elemHtml.attributes ??= HashMap<String, XUIProperty>();
        //   elemHtml.attributes["data-xui-slot-name"] =
        //       XUIProperty(prop.value.content);
        // }
      });
    }
  }

  Future processPhase2(
      XUIEngine engine, XUIElementHTML elemHtml, String parentXId) async {
    // gestion appel des native
    if (elemHtml.implementBy != null)
      for (var cmp in elemHtml.implementBy) {
        if (cmp.elemXUI is XUIElementNative) {
          await (cmp.elemXUI as XUIElementNative)
              .doProcessPhase2(engine.xuiFile, elemHtml);
        }
      }

    var slotInfo = SlotInfo();

    if (elemHtml?.attributes != null && elemHtml is! XUIElementHTMLText) {
      slotInfo.xid = elemHtml.attributes["data-xid"]?.content;
      if (slotInfo.xid != null) {
        if (elemHtml?.propertiesXUI != null) {
          slotInfo.slotname = elemHtml?.propertiesXUI[ATTR_SLOT_NAME]?.content;
        }
      } else {
        // affecte pour le designer un xid sur les slot sans xid
        var xidslot = elemHtml.attributes["data-xid-slot"]?.content;
        if (xidslot != null) {
          elemHtml.attributes["data-xid"] = XUIProperty("_" + xidslot);
        }
      }
    }

    // boucle sur les enfant
    if (elemHtml.children != null) {
      for (var child in elemHtml.children) {
        await processPhase2(engine, child,
            slotInfo.slotname == null ? parentXId : slotInfo.xid);
      }
    }
    //genere les infos de design (info, doc, etc...)

    if (slotInfo.xid != null) {
      if (slotInfo.slotname != null) {
        slotInfo.slotname = calculateProp(slotInfo.slotname, elemHtml);
        slotInfo.parentXid = parentXId;
        slotInfo.docId = getDocumentationID(elemHtml);
        slotInfo.idRessource = elemHtml.origin.idRessource;
        slotInfo.elementHTML = elemHtml;

        engine.mapInfo[slotInfo.xid] = slotInfo;

        // print("xid=<" +
        //     (slotInfo.xid ?? "") +
        //     "> pxid=<" +
        //     (slotInfo.parentXid ?? "") +
        //     "> slotname=<" +
        //     slotInfo.slotname +
        //     "> docId=<" +
        //     (slotInfo.docId ?? "-") +
        //     "> origin=<" +
        //     (slotInfo.idRessource ?? "-") +
        //     ">");

        // if (elemHtml.origin.tag == "xui-slot") {
        //  var a = elemHtml.parent.tag;
        // }
      }
    }

    return Future.value();
  }

  String getDocumentationID(XUIElementHTML elemHtml) {
    var docId = elemHtml.implementBy.first.elemXUI.xid;
    if (docId == "xui-slot") {
      docId = elemHtml.parent.tag;
      var parent = elemHtml.parent;
      while (parent != null) {
        if (parent.implementBy != null) {
          docId = docId + ":" + parent.implementBy.first.elemXUI.xid;
          break;
        }
        parent = parent.parent;
      }
    }
    return docId;
  }

  @override
  int compareTo(XUIModel other) {
    return priority.compareTo(other.priority);
  }
}

/************************************************************* */
class SlotInfo {
  String xid;
  String parentXid;
  String slotname;
  String docId;
  String idRessource;
  XUIElementHTML elementHTML;
}
