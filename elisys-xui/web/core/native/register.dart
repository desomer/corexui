import 'dart:collection';

import '../XUIEngine.dart';
import '../XUIFactory.dart';
import '../element/XUIElement.dart';
import '../element/XUIProperty.dart';

/************************************************************************************** */
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
    // recherche le nom du slot
    var slotName = null;
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

    // creer un slot visible si pas d'enfant
    if (html.children == null &&
        slotName != null &&
        engine.xuiFile.context.mode != "final") {
      var newChild = XUIElementXUI()..tag = TAG_DIV_SLOT;
      newChild.children = [];
      newChild.children.add(XUIElementText()..content = slotName);
      await XUIModel(this, MODE_ALL).doChild(newChild, html, engine);
    }

    int nb = html.getNbChild();

    html.children?.forEach((childHtml) {
      // affecte les attribut du slot sur les enfants
      var model = XUIElementXUI();
      XUIModel(model, MODE_ALL).processAttributes(childHtml);

      // affecte le nom du slot sur les enfants si doit etre accessible (avoir un slot name)
      if (slotName != null && engine.xuiFile.context.mode != MODE_FINAL) {
        childHtml.attributes ??= HashMap<String, XUIProperty>();
        var xidCal =
            XUIModel(html.origin, null).calculateProp(html.origin.xid, html);
        childHtml.attributes["data-" + ATTR_XID_SLOT] = XUIProperty(xidCal);
        if (isFull && nb==1) {
          if (childHtml.attributes["class"]==null)
            childHtml.attributes["class"] = XUIProperty("xui-class-slot-full");
          else
            childHtml.attributes["class"] = XUIProperty(childHtml.attributes["class"].content+" xui-class-slot-full");
        }
      }
    });

    return Future.value();
  }
}

/************************************************************************************** */
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
    var idResource = html.origin.propertiesXUI["path"].content;

    if (cacheText[idResource] == null)
      cacheText[idResource] =
          await engine.xuiFile.reader.provider.getResourceFutur(idResource);

    aText.content = cacheText[idResource];

    root.children ??= []..add(aText);

    Future<XUIModel> f = Future.sync(() => XUIModel(root, MODE_ALL));
    return f;
  }
}

/************************************************************************************** */
class NativeRegister {
  NativeRegister(XUIResource reader) {
    NativeInjectFile().register(reader);
    NativeSlot().register(reader);
  }
}
