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
      XUIResource xuifile, XUIElementHTML html) async {
    var root = XUIElementXUI();
    root.tag = TAG_NO_DOM;

    Future<XUIModel> f = Future.sync(() => XUIModel(root, MODE_ALL));
    return f;
  }

  @override
  Future doProcessPhase2(XUIResource xuifile, XUIElementHTML html) async {
    // recherche le nom du slot
    var slotName = null;
    html?.propertiesXUI?.entries?.forEach((f) {
      if (f.key.toLowerCase() == ATTR_SLOT_NAME) {
        slotName = f.value.content.toString();
      }
    });

    // creer un slot visible si pas d'enfant
    if (html.children == null &&
        slotName != null &&
        xuifile.context.mode != "final") {
      var newChild = XUIElementXUI()..tag = TAG_DIV_SLOT;
      newChild.children=[];
      newChild.children.add(XUIElementText()..content=slotName);
      await XUIModel(this, MODE_ALL).doChild(newChild, html, xuifile);
    }

    html.children?.forEach((childHtml) {
      // affecte les attribut du slot sur les enfants
      var model = XUIElementXUI();

      XUIModel(model, MODE_ALL).processAttributes(childHtml);

      // affecte le nom du slot sur les enfants si doit etre accessible (avoir un slot name)
      if (slotName != null && xuifile.context.mode != MODE_FINAL) {
        childHtml.attributes ??= HashMap<String, XUIProperty>();
        childHtml.attributes["data-xid-slot"] =
            XUIProperty(html.origin.xid);
      }
    });

    return Future.value();
  }
}

/************************************************************************************** */
class NativeInjectFile extends XUIElementNative {
  NativeInjectFile() {
    this.xid = "xui-inject";
  }

  var cacheText;

  @override
  Future<XUIModel> doProcessPhase1(
      XUIResource xuifile, XUIElementHTML html) async {
    var root = XUIElementXUI();
    root.tag = TAG_NO_DOM;

    var aText = XUIElementText();
    var idResource = html.origin.propertiesXUI["path"].content;

    if (cacheText==null)
        cacheText = await xuifile.reader.provider.getResourceFutur(idResource);
        
    aText.content=cacheText;

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
