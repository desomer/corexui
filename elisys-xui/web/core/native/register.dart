import 'dart:collection';

import '../XUIEngine.dart';
import '../XUIFactory.dart';
import '../element/XUIElement.dart';
import '../element/XUIProperty.dart';

class NativeRegister
{

  NativeRegister( XUIResource reader)
  {
      addNativeComponentInject(reader);
      addNativeComponentSlot(reader);
  }

  void addNativeComponentInject(XUIResource reader) {
    var aComponent = XUIElementNative();

    aComponent.fctPhase1 =  (XUIResource xuifile, XUIElementNative elem, XUIElementHTML html) async {
      var root = XUIElementXUI();
      root.tag = TAG_NO_DOM;

      var aText = XUIElementText();
      var idResource = html.origin.propertiesXUI["path"].content;

      aText.content = await xuifile.reader.provider.getResourceFutur(idResource);
      root.children ??= []..add(aText);

      Future<XUIModel> f = Future.sync(()=>XUIModel(root));
      return f;
    };

    reader.components["xui-inject"] ??= DicoOrdered()..add(XUIComponent(aComponent));
  }

  void addNativeComponentSlot(XUIResource reader) {
    var aComponent = XUIElementNative();

    aComponent.fctPhase1 =
         (XUIResource xuifile, XUIElementNative elem, XUIElementHTML html) async {
      var root = XUIElementXUI();
      root.tag = TAG_NO_DOM;
      Future<XUIModel> f = Future.sync(()=>XUIModel(root));
      return f;
    };

    aComponent.fctPhase2 =
        (XUIResource xuifile, XUIElementNative elem, XUIElementHTML html) {
      html.children?.forEach((childHtml) {
        if (html.origin.propertiesXUI != null) {
          html.origin.propertiesXUI.entries.forEach((f) {
            if (f.key.toLowerCase() == ATTR_SLOT_NAME) {
              childHtml.attributes ??= HashMap<String, XUIProperty>();
              childHtml.attributes["data-xid-impl"] =
                  XUIProperty(html.origin.xid);
            }
          });
        }
      });
    };

    reader.components["xui-slot"] ??= DicoOrdered()..add(XUIComponent(aComponent));
  }

}