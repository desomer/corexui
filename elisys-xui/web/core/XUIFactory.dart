import 'dart:collection';

import 'XUIConfigManager.dart';
import 'XUIEngine.dart' as cst;
import 'XUIEngine.dart';
import 'element/XUIElement.dart';
import 'element/XUIProperty.dart';

///------------------------------------------------------------------
class XUIHtmlBuffer {
  var html = StringBuffer();
  int idxTab = 0;
  bool trim = false;

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
  XUIComponent(e, m) : super(e, m, 0);
}

class XUIDesign extends XUIModel {
  XUIDesign(e, m, p) : super(e, m, p);
}

class XUIChild extends XUIModel {
  XUIChild(e, m) : super(e, m, 0);
}

/// gestion du binding
class XUIBinding {
  String namespace;
  String propName;
  String attr;
  dynamic value;
  String xid;
  String? type;

  XUIBinding(this.namespace, this.propName, this.attr, this.value, this.xid);
}

///------------------------------------------------------------------
///
/// gestion des designs ou des components
///
///------------------------------------------------------------------
class XUIModel implements Comparable<XUIModel> {
  int priority = 0; // gestion de la priorité d'application
  late XUIElementXUI elemXUI;
  String? mode; // final, template, design, etc...
  bool use = false;

  XUIModel(this.elemXUI, this.mode, this.priority);

  Future processPhase1(XUIEngine engine, XUIElementHTML elemHtml) async {
    var tag = elemXUI.tag;

    /********** AFFECTE LES INFO POUR LE DESIGNER *************/
    if (this is XUIComponent) {
      elemHtml.implementBy = (elemHtml.implementBy ?? [])
        ..add(this as XUIComponent);
    } else if (this is XUIDesign) {
      elemHtml.designBy = (elemHtml.designBy ?? [])..add(this as XUIDesign);
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

    // attribut
    _processAttributesPhase1(elemHtml);

    // properties
    _processPropertiesPhase1AndBind(elemHtml, engine);

    // lance les children
    await _processPhase1Children(elemHtml, engine);

    // calcul le xid  (ex : __parentxid__ , __idx__)
    var xidCal = elemHtml.calculatePropertyXUI(elemXUI.xid, null);

    // lance les design (pour affectation property utilise)
    await _processPhase1Design(xidCal, engine, elemHtml);

    // lance implementation xui si affecter par le design (ex: remplace un slot par un div)
    await _processPhase1Component(engine, elemHtml);

    // affecte les xid uniquement si child (pas design ni component)
    elemHtml.lastCalXid=xidCal;
    if (elemXUI.xid != null && engine.isActiveDataXid() ) {
      elemHtml.attributes ??= HashMap<String, XUIProperty>();
      if (this is! XUIComponent && this is! XUIDesign) {
        elemHtml.attributes!["data-" + ATTR_XID] = XUIProperty(xidCal);
      }
    }

    return Future.value();
  }

  Future _processPhase1Component(
      XUIEngine engine, XUIElementHTML elemHtml) async {
    if (elemXUI.tag != null /*&& (elem.tag != tag || this is! XUIComponent)*/) {
      var cmp = engine.xuiFile.searchComponent(elemXUI.tag!);

      if (cmp != null) {
        for (var item in cmp.sort(engine.xuiFile.context)) {
          await item.processPhase1(engine, elemHtml);
        }
      }
    }
  }

  Future _processPhase1Design(
      String? xid, XUIEngine engine, XUIElementHTML elemHtml) async {
    if (xid != null && this is! XUIDesign) {
      List<DicoOrdered<XUIDesign>> listDico = [];
      engine.xuiFile.searchDesign(listDico, xid);

      for (var dico in listDico) {
        for (var design in dico.sort(engine.xuiFile.context)) {
          design.use=true;
          await design.processPhase1(engine, elemHtml);
        }
      }
    }
  }

  Future _processPhase1Children(
      XUIElementHTML elemHtml, XUIEngine engine) async {
    /**************** XUI-FOR  *****************/
    int nbFor = 1;
    String? varIdx;
    if (elemHtml.propertiesXUI != null) {
      XUIProperty? xuifor = elemHtml.propertiesXUI!["for"];
      if (xuifor != null) {
        varIdx = xuifor.content.toString();

        var nbs = elemHtml.calculatePropertyXUI("[[" + elemHtml.getForVar() + "]]", null);
        bool okParse = true;
        try {
          nbFor = int.parse(nbs!);
        } on Exception catch (e) {
          okParse=false;
          XUIConfigManager.printc( "************************* ret var for " +
              nbs! +
              " " +
              e.toString());
        }

        if (!okParse && elemHtml.implementBy != null)
            {
              var doc = engine.docInfo[elemHtml.implementBy?.first.elemXUI.xid ?? ""];
              print("--------------> "+(doc?.name ?? ""));
            }

      }
    }
    /****************************************/

    if (elemXUI.children != null) {
      for (var i = 0; i < nbFor; i++) {
        for (var item in elemXUI.children!) {
          if (varIdx != null) {
            // affecte les proprties de la boucle FOR
            item.propertiesXUI ??= HashMap<String, XUIProperty>();
            item.propertiesXUI![varIdx] = XUIProperty(i.toString());
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

      return Future.sync(() => elemHtml.children!.add(childHtml));
    }
  }

  void _processAttributesPhase1(XUIElementHTML elemHtml) {
    if (elemXUI.attributes != null) {
      elemHtml.attributes ??= HashMap<String, XUIProperty>();
      elemXUI.attributes!.entries.forEach((f) {
        String? v = f.value.content;

        if (f.key.toLowerCase() == "style") {
          // complete les styles
          XUIProperty? style = elemHtml.attributes![f.key];
          _completeAttributPhase1(style, elemHtml, f, v, ";");
        } else if (f.key.toLowerCase() == "class") {
          // complete les classes
          XUIProperty? classe = elemHtml.attributes![f.key];
          _completeAttributPhase1(classe, elemHtml, f, v, " ");
        } else {
          elemHtml.attributes![f.key] = XUIProperty(v);
        }
      });
    }
  }

  // gestion des [[xxx]] dans les style et class
  void _completeAttributPhase1(XUIProperty? style, XUIElementHTML elemHtml,
      MapEntry<String, XUIProperty> f, String? v, String sep) {
    if (style == null) {
      elemHtml.attributes![f.key] = XUIProperty(v);
    } else {
      String val = elemHtml.attributes![f.key]!.content + sep + v;
      elemHtml.attributes![f.key]!.content = val;
    }
  }

  void addProperties(String key, String value) {
    elemXUI.propertiesXUI ??= HashMap<String, XUIProperty>();
    elemXUI.propertiesXUI![key] = XUIProperty(value);
  }

  void _processPropertiesPhase1AndBind(
      XUIElementHTML elemHtml, XUIEngine engine) {
    if (elemXUI.propertiesXUI != null) {

      bool withAttributPhase2 = false;
      elemXUI.propertiesXUI!.entries.forEach((prop) {
        elemHtml.propertiesXUI ??= HashMap<String, XUIProperty>();

        var keyLowercase = prop.key.toLowerCase();

        if (keyLowercase == cst.ATTR_NO_DOM) {
          elemHtml.tag = TAG_NO_DOM; // si xui-no-dom alors retire la tag
        }

        if (keyLowercase != cst.ATTR_XID) {
          // n'affecte pas le XID car gerer par attribut xid  => affecte tous les autres
          XUIProperty p = prop.value;

          bool hasEvent = engine.bindingManager
              .processPropertiesBindingPhase1(prop, this, elemHtml);
          if (hasEvent) 
          {
            withAttributPhase2 = true;
            var parseInfo = ParseInfo(prop, null, ParseInfoMode.PROP);
            String? varNameSpace = elemHtml.searchPropertyXUI(PROP_VAR_NAMESPACE+"@0+", 0, parseInfo) as String?; 
            var propEvent = XUIPropertyBinding(prop.value.content, varNameSpace??"main", null);
            elemHtml.propertiesXUI![prop.key]= propEvent;
          }
          else
            elemHtml.propertiesXUI![prop.key] = p;
        }
      });

      if (withAttributPhase2) {
        // passe aprés l'affectation de properties pour avec avoir l'ensemble de properties (afin de calculer le xid)
        elemHtml.propertiesXUI!.entries.forEach((prop) {
          if (prop.key.toLowerCase() != cst.ATTR_XID) {
            engine.bindingManager
                .processPropertiesBindingPhase1Event(prop, elemHtml);   // recherche les event
          }
        });
      }

    }
  }

  //////////////////////////////////////////// PHASE 2 //////////////////////////////////////////

  Future processPhase2(
      XUIEngine engine, XUIElementHTML elemHtml, String? parentXId) async {

    if (elemHtml.implementBy != null) {
      for (var cmp in elemHtml.implementBy!) {
        // gestion appel des native
        if (cmp.elemXUI is XUIElementNative) {
          await (cmp.elemXUI as XUIElementNative)
              .doProcessPhase2(engine, elemHtml);
        }

        var hasJSonValidator = engine.bindingManager.afterJsonValidator[cmp.elemXUI.xid];
        if (hasJSonValidator!=null)
        {
          String xid = elemHtml.originElemXUI?.xid as String;
          //print(">>>>>>>>>>>>>>>>>>>>>>>>>>>><" + cmp.elemXUI.xid! + "=> " + xid!);
          engine.bindingManager.validatorInfo[xid]=XUIBinding("", cmp.elemXUI.xid!, "","", xid);
        }
      }
    }

    var slotInfo = SlotInfo();
    bool addSlotInfo = false;
    if (elemHtml.attributes != null && elemHtml is! XUIElementHTMLText) {
      // recherche les info de slot designable
      //var xid = elemHtml.attributes!["data-" + ATTR_XID]?.content;
      slotInfo.xid = elemHtml.lastCalXid;   //xid;

      if (slotInfo.xid != null) {
        addSlotInfo = true;
        if (elemHtml.propertiesXUI != null &&
            elemHtml.propertiesXUI![ATTR_NO_DESIGN] != null) {
          addSlotInfo = false;
          if (XUIConfigManager.verboseSlotInfo) {
            XUIConfigManager.printc(
                "-- xui-no-design (no add slot info) ---> " + slotInfo.xid!);
          }
        }
        if (addSlotInfo && elemHtml.propertiesXUI != null) {
          slotInfo.slotname = elemHtml.propertiesXUI![ATTR_SLOT_NAME]?.content;
        }
      } else {
        // affecte, pour le designer, un xid sur les slot sans xid
        var xidslot = elemHtml.attributes!["data-" + ATTR_XID_SLOT]?.content;
        if (xidslot != null) {
          elemHtml.attributes!["data-" + ATTR_XID] = XUIProperty(SLOT_PREFIX + xidslot);
        }
      }
    }

    // boucle sur les enfant
    if (elemHtml.children != null) {
      for (var child in elemHtml.children!) {
        await processPhase2(engine, child as XUIElementHTML,
            addSlotInfo ? slotInfo.xid : parentXId);
      }
    }

    //genere les infos de design (info, doc, etc...)
    if (addSlotInfo &&  engine.isAddSlotInfo()) {
      slotInfo.parentXid = parentXId;

      slotInfo.idRessource = elemHtml.originElemXUI!.idRessource;
      slotInfo.elementHTML = elemHtml;
      slotInfo.implement = elemHtml.implementBy?.first.elemXUI.xid;
      slotInfo.docId = getDocumentationID(elemHtml);

      String? hasFor = elemHtml.propertiesXUI?[PROP_VAR_ITEMS]?.content;
      if (hasFor != null)
        slotInfo.mapTag["for"] = hasFor;
      else
        slotInfo.mapTag.remove("for");

      slotInfo.designInfo = "no design";
      if (elemHtml.designBy != null) {
        slotInfo.designInfo = "(" + elemHtml.designBy!.length.toString() + ")";
        for (XUIDesign item in elemHtml.designBy!) {
          slotInfo.designInfo = slotInfo.designInfo +
              "[" +
              (item.elemXUI.idRessource ?? "?") +
              "]";
        }
      }

      if (slotInfo.slotname != null) {
        slotInfo.slotname =
            elemHtml.calculatePropertyXUI(slotInfo.slotname, null);
      }
      engine.mapSlotInfo[slotInfo.xid!] = slotInfo;
    }

    return Future.value();
  }

  String? getDocumentationID(XUIElementHTML elemHtml) {
    if (elemHtml.implementBy == null) {
      return null; // cas des xui-no-dom
    }

    var implementId = elemHtml.implementBy!.first.elemXUI.xid;
    var docId = implementId;

    if (elemHtml.propertiesXUI != null) {
      XUIProperty? docIdProp = elemHtml.propertiesXUI![ATTR_DOC_ID];
      if (docIdProp != null) docId = docIdProp.content;
    }

    // si tag XUI-SLOT => cherche implement du parent
    if (implementId == TAG_SLOT && docId == implementId) {
      docId = elemHtml.parent!.tag!;
      var parent = elemHtml.parent;
      while (parent != null) {
        if (parent.implementBy != null) {
          docId = docId! + ":" + parent.implementBy!.first.elemXUI.xid!;
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
