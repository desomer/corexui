import 'dart:collection';

import '../XUIConfigManager.dart';
import '../XUIEngine.dart';
import '../XUIFactory.dart';
import '../element/XUIElement.dart';
import '../element/XUIProperty.dart';

///------------------------------------------------------------------
class NativeSlot extends XUIElementNative {
  NativeSlot() {
    xid = TAG_SLOT;
  }
  @override
  Future<XUIModel> doProcessPhase1(XUIEngine engine, XUIElementHTML html) async {
    final root = XUIElementXUI();
    root.tag = TAG_NO_DOM;
    final Future<XUIModel> f = Future.sync(() => XUIModel(root, MODE_ALL, 0));
    return f;
  }

  @override
  Future doProcessPhase2(XUIEngine engine, XUIElementHTML html) async {
    // recherche le nom du slot et si celui ci et un slot full
    String? slotName;
    bool isFull = false;

    // ignore: avoid_function_literals_in_foreach_calls
    html.propertiesXUI?.entries.forEach((f) {
      if (f.key.toLowerCase() == ATTR_SLOT_NAME) {
        slotName = f.value.content.toString();
      }
      if (f.key.toLowerCase() == ATTR_SLOT_FULL) {
        isFull = true;
      }
    });

    // test slot text vide => alors pas d'enfant
    if (html.children?.length == 1) {
      if (html.children!.first is XUIElementHTMLText) {
        html.children = null;
      }
    }

    final isModeDesign = engine.isModeDesign() || XUIConfigManager.forceSlotInfo;
    String? xidCal;
    if (isModeDesign && html.originElemXUI != null) {
      xidCal = html.calculatePropertyXUI(html.originElemXUI!.xid, null);
    }

    final isSlotButNotCopyzone = xidCal != XUI_COPYZONE_SLOT;

    // si mode design => creer un slot visible si pas d'enfant sauf XUI_COPYZONE_SLOT
    if (isModeDesign && html.children == null && isSlotButNotCopyzone) {
      final newChild = XUIElementXUI()..tag = TAG_DIV_SLOT;
      newChild.children = [];
      newChild.children!.add(XUIElementText()..content = StringBuffer(slotName.toString()));

      newChild.attributes = HashMap<String, XUIProperty>();
      newChild.attributes!["class"] = XUIProperty("text-truncate");  // trunc le texte si trop long

      if (html.originElemXUI!.attributes != null) {
        // affecte les styles et les class du slot  (ex : flow et le display:inline flex)
        newChild.attributes = HashMap<String, XUIProperty>();
        if (html.originElemXUI!.attributes![ATTR_STYLE_SLOT] != null) {
          newChild.attributes!["style"] =
              html.originElemXUI!.attributes![ATTR_STYLE_SLOT]!;
        }

        _addAttributClassStyle("class", html, newChild," ");
        _addAttributClassStyle("style", html, newChild,";");
      }
      // affecte l'implementation du TAG_DIV_SLOT sur le newChild
      await XUIModel(this, MODE_ALL,0).doChildPhase1(newChild, html, engine);
    }

    // affecte l'identifiant xid du slot sur le parent si le parent en a pas
    final int nbChild = html.getNbChildNoText();
    int nbChildNoSlot = 0;
    final isFlow = html.originElemXUI!=null && html.originElemXUI!.tag == "xui-flow";
    final isFlowParent = html.parent!=null && html.parent!.originElemXUI!=null && html.parent!.originElemXUI!.tag == "xui-flow";

    html.children?.forEach((childHtml) {

      // affecte le nom du slot sur les enfants si doit etre accessible (avoir un slot xid)
      if (isModeDesign && isSlotButNotCopyzone) {
        childHtml.attributes ??= HashMap<String, XUIProperty>();
        // affecte le xid-slot sur les enfant non slot
        if (childHtml is! XUIElementHTMLText) {

          if (childHtml.tag != TAG_NO_DOM) {
            var xidSlot = xidCal.toString();
            if (isFlowParent && (childHtml as XUIElementHTML).originElemXUI!.tag!=TAG_DIV_SLOT)
              {
                  xidSlot  = xidCal.toString().substring(0 , xidCal.toString().lastIndexOf("-"));
                  xidSlot  = xidSlot.substring(0 , xidSlot.lastIndexOf("-"));
                  //print("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee "+ xidSlot + " tag " + (html.originElemXUI!.tag??"") +  " p.tag=" + ((childHtml as XUIElementHTML).originElemXUI!.tag??""));
              }

            childHtml.attributes!["data-$ATTR_XID_SLOT"] = XUIProperty(xidSlot);
            nbChildNoSlot++;
          }
        }
      }

      // pour la selection d'un for
      // affecte la class full sur l'enfant si full et unique
      if (nbChild == 1) {
        _addAttributClassStyle("class", html, childHtml," ");
        _addAttributClassStyle("style", html, childHtml,";");
        _addAttributClassStyle("v-bind:data-for-idx", html, childHtml," ");
        _addAttributClassStyle("data-for-map", html, childHtml," ");

        if (isFull) {
          childHtml.attributes ??= HashMap<String, XUIProperty>();
          if (childHtml.attributes!["class"] == null) {
            childHtml.attributes!["class"] = XUIProperty("xui-class-slot-full");
          } else {
            // ignore: require_trailing_commas
            childHtml.attributes!["class"] = XUIProperty(
                (childHtml.attributes!["class"]!.content + " xui-class-slot-full")
                    .trim());
          }
        }
      }
    });

    if (isModeDesign && xidCal!=null && (nbChildNoSlot == 0) && !isFlow) {
      //recherche un parent affichable pour gerer la selection des slot (displaySelectorByXid)
      var p = html.parent;
      while (p != null) {
        if (p.tag != null && !p.tag!.startsWith("xui")) {
           p.attributes ??= HashMap<String, XUIProperty>();
           p.attributes!["data-$ATTR_XID_SLOT-$xidCal"] = XUIProperty(true);
          break;
        }
        p = p.parent;
      }
    }

    return Future.value();
  }

  void _addAttributClassStyle(String attr, XUIElementHTML html, XUIElement newChild, String sep) {
    if (html.originElemXUI?.attributes != null &&
        html.originElemXUI!.attributes![attr] != null) {
      newChild.attributes ??= HashMap<String, XUIProperty>();

      String val;
      if (newChild.attributes![attr] == null) {
        val = html.originElemXUI!.attributes![attr]!.content as String;
        newChild.attributes![attr] = XUIProperty(val);
      } else {
        val = newChild.attributes![attr]!.content.toString() +
            sep +
            html.originElemXUI!.attributes![attr]!.content.toString();
        newChild.attributes![attr]!.content=val;
      }
    }
  }
}

///------------------------------------------------------------------
class NativeInjectFile extends XUIElementNative {
  // dictionnaire de cache de fichier
  Map<String, StringBuffer> cacheText = {};

  NativeInjectFile() {
    xid = "xui-inject";
  }

  @override
  Future<XUIModel> doProcessPhase1(
      XUIEngine engine, XUIElementHTML html) async {
    final root = XUIElementXUI();
    root.tag = TAG_NO_DOM;

    final aText = XUIElementText();
    final String idResource = html.originElemXUI!.propertiesXUI!["path"]!.content as String;

    if (cacheText[idResource] == null) {
      cacheText[idResource] = await engine.xuiFile.reader.provider.getResourceFutur(idResource) as StringBuffer;
    }

    aText.content = cacheText[idResource]!;

    root.children ??= []..add(aText);

    final Future<XUIModel> f = Future.sync(() => XUIModel(root, MODE_ALL,0));
    return f;
  }
}

// ignore: constant_identifier_names
const JS_BINDING="data-binding";
const CSS_BINDING= "data-css";

///------------------------------------------------------------------
class NativeInjectText extends XUIElementNative {
  // dictionnaire de cache de fichier
  static var cacheText = { JS_BINDING:  StringBuffer(), CSS_BINDING : StringBuffer() };   //gestion 

  static StringBuffer? getcacheText(idResource)
  {
      return cacheText[idResource];
  }

  NativeInjectText() {
    this.xid = "xui-inject-text";
  }

  @override
  Future<XUIModel> doProcessPhase1(
      XUIEngine engine, XUIElementHTML html) async {
    var root = XUIElementXUI();
    root.tag = TAG_NO_DOM;

    var aText = XUIElementText();
    var idResource = html.originElemXUI!.propertiesXUI!["path"]!.content;

    aText.content = cacheText[idResource]!;

    root.children ??= []..add(aText);

    Future<XUIModel> f = Future.sync(() => XUIModel(root, MODE_ALL, 0));
    return f;
  }
}

///------------------------------------------------------------------
class NativeRegister {
  NativeRegister(XUIResource reader) {
    NativeInjectFile().register(reader);
    NativeSlot().register(reader);
    NativeInjectText().register(reader);
  }
}
