import 'dart:collection';

import '../XUIEngine.dart';
import '../XUIFactory.dart';
import '../element/XUIElement.dart';
import '../element/XUIProperty.dart';

///------------------------------------------------------------------
class NativeSlot extends XUIElementNative {
  NativeSlot() {
    this.xid = "xui-slot";
  }
  @override
  Future<XUIModel> doProcessPhase1(
      XUIEngine engine, XUIElementHTML html) async {
    var root = XUIElementXUI();
    root.tag = TAG_NO_DOM;
    Future<XUIModel> f = Future.sync(() => XUIModel(root, MODE_ALL));
    return f;
  }

  @override
  Future doProcessPhase2(XUIEngine engine, XUIElementHTML html) async {
    // recherche le nom du slot et si celui ci et un slot full
    var slotName;
    bool isFull = false;
    html?.propertiesXUI?.entries?.forEach((f) {
      if (f.key.toLowerCase() == ATTR_SLOT_NAME) {
        slotName = f.value.content.toString();
      }
      if (f.key.toLowerCase() == ATTR_SLOT_FULL) {
        isFull = true;
      }
    });

    // test slot text vide => alors pas d'enfant
    if (html.children?.length == 1) {
      if (html.children.first is XUIElementHTMLText) {
        html.children = null;
      }
    }

    var isModeDesign = engine.isModeDesign();

    // si mode design => creer un slot visible si pas d'enfant
    if (isModeDesign && html.children == null && slotName != null) {
      var newChild = XUIElementXUI()..tag = TAG_DIV_SLOT;
      newChild.children = [];
      newChild.children.add(XUIElementText()..content = slotName);
      if (html.originElemXUI.attributes!=null) {
        // affecte les styles et les class du slot  (ex : flow et le display:inline flex)
        newChild.attributes=HashMap<String, XUIProperty>();
        if (html.originElemXUI.attributes["style"]!=null) {
          newChild.attributes["style"] = html.originElemXUI.attributes["style"];
        }
        if (html.originElemXUI.attributes["class"]!=null) {
          newChild.attributes["class"] = html.originElemXUI.attributes["class"];
        }
      }
      await XUIModel(this, MODE_ALL).doChildPhase1(newChild, html, engine);  // affecte l'implementation du TAG_DIV_SLOT sur le newChild
    }

    // affecte l'identifiant xid du slot sur le parent si le parent en a pas
    var xidCal;
    if (html.originElemXUI != null) {
      xidCal = html.calculatePropertyXUI(html.originElemXUI.xid);
    }

    int nbChild = html.getNbChildNoText();
    int nbChildNoSlot = 0;
    html.children?.forEach((childHtml) {
      // affecte les attribut du slot sur les enfants 

     //var model = XUIElementXUI();
     // XUIModel(model, MODE_ALL).processAttributes(childHtml);

      // affecte le nom du slot sur les enfants si doit etre accessible (avoir un slot name)
      if (isModeDesign && slotName != null) {
        childHtml.attributes ??= HashMap<String, XUIProperty>();

        // affecte le xui-slot sur les enfant non slot
        if (childHtml is! XUIElementHTMLText) {
          if (childHtml.tag != TAG_NO_DOM) {
            childHtml.attributes["data-" + ATTR_XID_SLOT] = XUIProperty(xidCal);
            nbChildNoSlot++;
          }
        }
      }
      // affect la class full sur l'enfant si full et unique
      if (isFull && nbChild == 1) {
        childHtml.attributes ??= HashMap<String, XUIProperty>();
        if (childHtml.attributes["class"] == null) {
          childHtml.attributes["class"] = XUIProperty("xui-class-slot-full");
        } else {
          childHtml.attributes["class"] = XUIProperty(
              childHtml.attributes["class"].content + " xui-class-slot-full");
        }
      }
    });

    if (isModeDesign && (nbChildNoSlot == 0 /*|| nbChildNoSlot > 1*/)) {
      //recherche un parent affichable pour gerer la selection des slot (displaySelectorByXid)
      var p = html.parent;
      while (p != null) {
        if (p.tag != null && !p.tag.startsWith("xui")) {
          p.attributes ??= HashMap<String, XUIProperty>();
          p.attributes["data-" + ATTR_XID_SLOT + "-" + xidCal] =
              XUIProperty(true);
          break;
        }
        p = p.parent;
      }
    }

    return Future.value();
  }
}

///------------------------------------------------------------------
class NativeInjectFile extends XUIElementNative {
  // dictionnaire de cache de fichier
  var cacheText = {};

  NativeInjectFile() {
    this.xid = "xui-inject";
  }

  @override
  Future<XUIModel> doProcessPhase1(
      XUIEngine engine, XUIElementHTML html) async {
    var root = XUIElementXUI();
    root.tag = TAG_NO_DOM;

    var aText = XUIElementText();
    var idResource = html.originElemXUI.propertiesXUI["path"].content;

    if (cacheText[idResource] == null) {
      cacheText[idResource] =
          await engine.xuiFile.reader.provider.getResourceFutur(idResource);
    }

    aText.content = cacheText[idResource];

    root.children ??= []..add(aText);

    Future<XUIModel> f = Future.sync(() => XUIModel(root, MODE_ALL));
    return f;
  }
}

///------------------------------------------------------------------
class NativeRegister {
  NativeRegister(XUIResource reader) {
    NativeInjectFile().register(reader);
    NativeSlot().register(reader);
  }
}
