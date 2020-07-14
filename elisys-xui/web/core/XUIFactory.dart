import 'dart:collection';

import 'XUIEngine.dart' as cst;
import 'XUIEngine.dart';
import 'element/XUIElement.dart';
import 'element/XUIProperty.dart';

///------------------------------------------------------------------
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

///------------------------------------------------------------------
class XUIComponent extends XUIModel {
  XUIComponent(e, m) : super(e, m);
}

class XUIDesign extends XUIModel {
  XUIDesign(e, m) : super(e, m);
}

class XUIChild extends XUIModel {
  XUIChild(e, m) : super(e, m);
}

///------------------------------------------------------------------
///
/// gestion des designs ou des components
///
///------------------------------------------------------------------

class XUIModel implements Comparable<XUIModel> {
  int priority = 0; // gestion de la priorité d'application
  XUIElementXUI elemXUI;
  String mode; // final, template, design, etc...

  XUIModel(this.elemXUI, this.mode);

  Future processPhase1(XUIEngine engine, XUIElementHTML elemHtml) async {
    var tag = elemXUI.tag;

    /********** AFFECTE LES INFO POUR LE DESIGNER *************/
    if (this is XUIComponent) {
      elemHtml.implementBy = (elemHtml.implementBy ?? [])..add(this);
    } else if (this is XUIDesign) {
      elemHtml.designBy = (elemHtml.designBy ?? [])..add(this);
    }

    /*********** EXECUTE LES NATIVES ********/
    if (elemXUI is XUIElementNative) {
      XUIModel model =
          await (elemXUI as XUIElementNative).doProcessPhase1(engine, elemHtml);

      await model.processPhase1(engine, elemHtml); // lance le nouveau modele

      return Future.value();
    }
    /*****************************************************************/
    if (tag != null) elemHtml.tag = tag;

    // properties
    processAttributes(elemHtml);

    // properties
    processProperties(elemHtml, engine.xuiFile);

    // lance les children
    await processPhase1Children(elemHtml, engine);

    // calcul le xid  (ex : __parentxid__ , __idx__)
    var xidCal = elemHtml.calculatePropertyXUI(elemXUI.xid, null);

    // lance les design (pour affectation property utilise)
    await processPhase1Design(xidCal, engine, elemHtml);

    // lance implementation xui si affecter par le design (ex: remplace un slot par un div)
    await processPhase1Component(engine, elemHtml);

    // affecte les xid uniquement si child (pas design ni component)
    if (elemXUI.xid != null && engine.xuiFile.context.mode != MODE_FINAL) {
      elemHtml.attributes ??= HashMap<String, XUIProperty>();
      if (this is! XUIComponent && this is! XUIDesign) {
        elemHtml.attributes["data-" + ATTR_XID] = XUIProperty(xidCal);
      }
    }

    return Future.value();
  }

  Future processPhase1Component(
      XUIEngine engine, XUIElementHTML elemHtml) async {
    if (elemXUI.tag != null /*&& (elem.tag != tag || this is! XUIComponent)*/) {
      var cmp = engine.xuiFile.searchComponent(elemXUI.tag);

      if (cmp != null) {
        for (var item in cmp.sort(engine.xuiFile.context)) {
          await item.processPhase1(engine, elemHtml);
        }
      }
    }
  }

  Future processPhase1Design(
      String xid, XUIEngine engine, XUIElementHTML elemHtml) async {
    if (xid != null && this is! XUIDesign) {
      // if (xid=="xui-script-data") {
      //           xid="xui-script-data";
      // }

      List<DicoOrdered<XUIDesign>> listDico = [];
      engine.xuiFile.searchDesign(listDico, xid);

      for (var dico in listDico) {
        for (var item in dico.sort(engine.xuiFile.context)) {
          await item.processPhase1(engine, elemHtml);
        }
      }
    }
  }

  Future processPhase1Children(
      XUIElementHTML elemHtml, XUIEngine engine) async {
    /**************** FOR  *****************/
    int nb = 1;
    String varIdx;
    if (elemHtml?.propertiesXUI != null) {
      XUIProperty xuifor = elemHtml.propertiesXUI["for"];
      if (xuifor != null) {
        varIdx = xuifor.content.toString();

        nb = int.parse(elemHtml.calculatePropertyXUI(
            elemHtml.propertiesXUI["nb"]?.content?.toString() ?? "1" , null) );
      }
    }
    /****************************************/

    if (elemXUI.children != null) {
      for (var i = 0; i < nb; i++) {
        for (var item in elemXUI.children) {
          if (varIdx != null) {
            // affecte les proprties de la boucle FOR
            item.propertiesXUI ??= HashMap<String, XUIProperty>();
            item.propertiesXUI[varIdx] = XUIProperty(i.toString());
            // item.propertiesXUI[ATTR_PARENT_XID] = XUIProperty(
            //     elemHtml.calculatePropertyXUI(elemHtml.originElemXUI.xid));
          }

          await doChildPhase1(item, elemHtml, engine);
        }
      }
    }
    return Future.value();
  }

  Future doChildPhase1(
      childXUI, XUIElementHTML elemHtml, XUIEngine engine) async {
    if (childXUI is XUIElementXUI) {
      var childHtml;

      if (childXUI is XUIElementText) {
        childHtml = XUIElementHTMLText();
        childHtml.content = childXUI.content;
        childHtml.parent = elemHtml;
        childHtml.originElemXUI = childXUI;
      } else {
        childHtml = XUIElementHTML();
        childHtml.parent = elemHtml;
        childHtml.originElemXUI = childXUI;

        var model = XUIChild(childXUI, MODE_ALL);
        await model.processPhase1(engine, childHtml);
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
        } else {
          elemHtml.attributes[f.key] = XUIProperty(v);
        }
      });
    }
  }

  void completeAttribut(XUIProperty style, XUIElementHTML elemHtml,
      MapEntry<String, XUIProperty> f, String v, String sep) {
    if (style == null) {
      elemHtml.attributes[f.key] = XUIProperty(v);
    } else {
      String val = elemHtml.attributes[f.key].content + sep + v;
      elemHtml.attributes[f.key].content = val;
    }
  }

  void addProperties(String key, String value) {
    elemXUI.propertiesXUI ??= HashMap<String, XUIProperty>();
    elemXUI.propertiesXUI[key] = XUIProperty(value);
  }

  void processProperties(XUIElementHTML elemHtml, XUIResource xuifile) {
    if (elemXUI.propertiesXUI != null) {
      elemXUI.propertiesXUI.entries.forEach((prop) {
        elemHtml.propertiesXUI ??= HashMap<String, XUIProperty>();

        if (prop.key.toLowerCase() == cst.ATTR_NO_DOM) {
          elemHtml.tag = TAG_NO_DOM; // si xui-no-dom alors retire la tag
        }

        if (prop.key.toLowerCase() != cst.ATTR_XID) {
          // n'affecte pas le XID car gerer par attribut xid
          elemHtml.propertiesXUI[prop.key] = prop.value;
        }
      });
    }
  }

  Future processPhase2(
      XUIEngine engine, XUIElementHTML elemHtml, String parentXId) async {
    // gestion appel des native
    if (elemHtml.implementBy != null) {
      for (var cmp in elemHtml.implementBy) {
        if (cmp.elemXUI is XUIElementNative) {
          await (cmp.elemXUI as XUIElementNative)
              .doProcessPhase2(engine, elemHtml);
        }
      }
    }

    var slotInfo = SlotInfo();
    bool addSlotInfo = false;
    if (elemHtml?.attributes != null && elemHtml is! XUIElementHTMLText) {
      // recherche les info de slot designable
      slotInfo.xid = elemHtml.attributes["data-" + ATTR_XID]?.content;
      if (slotInfo.xid != null) {
        addSlotInfo = true;
        if (elemHtml?.propertiesXUI != null &&
            elemHtml.propertiesXUI[ATTR_NO_DESIGN] != null) {
          addSlotInfo = false;
          //print("--------------------- no designable ---> " + slotInfo.xid);
        }
        if (addSlotInfo && elemHtml?.propertiesXUI != null) {
          slotInfo.slotname = elemHtml.propertiesXUI[ATTR_SLOT_NAME]?.content;
        }
      } else {
        // affecte, pour le designer, un xid sur les slot sans xid
        var xidslot = elemHtml.attributes["data-" + ATTR_XID_SLOT]?.content;
        if (xidslot != null) {
          elemHtml.attributes["data-" + ATTR_XID] =
              XUIProperty(SLOT_PREFIX + xidslot);
        }
      }
    }

    // boucle sur les enfant
    if (elemHtml.children != null) {
      for (var child in elemHtml.children) {
        await processPhase2(
            engine, child, addSlotInfo ? slotInfo.xid : parentXId);
      }
    }

    //genere les infos de design (info, doc, etc...)
    if (addSlotInfo && engine.isModeDesign()) {
      slotInfo.parentXid = parentXId;

      slotInfo.idRessource = elemHtml.originElemXUI.idRessource;
      slotInfo.elementHTML = elemHtml;
      slotInfo.implement = elemHtml.implementBy?.first?.elemXUI?.xid;
      slotInfo.docId = getDocumentationID(elemHtml);

      if (slotInfo.slotname != null) {
        slotInfo.slotname = elemHtml.calculatePropertyXUI(slotInfo.slotname, null);
      }
      if (false) {
        print("slot info phase 2 " + slotInfo.xid);
      }
      engine.mapInfo[slotInfo.xid] = slotInfo;
    }

    return Future.value();
  }

  String getDocumentationID(XUIElementHTML elemHtml) {
    if (elemHtml.implementBy == null) {
      return null; // cas des xui-no-dom
    }

    var implementId = elemHtml.implementBy.first.elemXUI.xid;
    var docId = implementId;

    // for (XUIComponent comp in elemHtml.implementBy) {
    //   if (comp.elemXUI.propertiesXUI != null) {
    //     XUIProperty docIdProp = comp.elemXUI.propertiesXUI[ATTR_DOC_ID];
    //     if (docIdProp != null) docId = docIdProp.content;
    //   }
    // }

    if (elemHtml.propertiesXUI != null) {
      XUIProperty docIdProp = elemHtml.propertiesXUI[ATTR_DOC_ID];
      if (docIdProp != null) docId = docIdProp.content;
    }

    if (implementId == "xui-slot" && docId==implementId) {
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
