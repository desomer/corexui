import 'dart:async';
import 'dart:collection';
import '../XUIEngine.dart' as cst;
import '../XUIEngine.dart';
import '../XUIFactory.dart';
import 'XUIProperty.dart';

abstract class XUIElement {
  // identifie l'implementation HTML ex: type panel (div, h1, span) input (label +
  // combo + action + desc + flag)
  String tag;

  // les attribut XHTML
  HashMap<String, XUIProperty> attributes;

  // les enfants
  List<XUIElement> children;

  // les prop xui
  HashMap<String, XUIProperty> propertiesXUI;

  bool isEmpty() {
    return attributes == null && children == null && propertiesXUI == null;
  }
}

class XUIElementHTML extends XUIElement {
  XUIElementHTML parent;

  XUIElementXUI origin;
  List<XUIComponent> implementBy;
  List<XUIDesign> designBy;

  int getNbChild() {
    int nb = 0;
    children?.forEach((c) {
      if (c is! XUIElementHTMLText) {
        nb++;
      }
    });
    return nb;
  }

  XUIElementHTML firstChildNoText() {
    if (children != null) {
      for (var item in children) {
         if (item is! XUIElementHTMLText) {
           return item;
         }
      }
    }
    return null;
  }

  dynamic searchPropertyXUI(String tag) {
    if (tag.contains("@")) {
      var atTag = tag.split("@");
      tag = atTag[0];
      var atHtml = atTag[1];
      if (atHtml == "-1") {
        return firstChildNoText().searchPropertyXUI(tag);
      }
    }

    XUIProperty prop = propertiesXUI == null ? null : propertiesXUI[tag];
    if (prop != null) {
      return prop.content;
    } else if (parent != null) return parent.searchPropertyXUI(tag);
  }

  dynamic processContent(String content, ParseInfoMode mode) {
    ParseInfo parseInfo = ParseInfo(content, mode);
    try {
      XUIProperty.parse(parseInfo, (String tag) {
        var ret = searchPropertyXUI(tag);
        return ret != null
            ? ret
            : ((mode == ParseInfoMode.CONTENT ? ("[" + tag + "]") : ""));
      });
    } catch (e, s) {
      print("pb parse $e $s");
      print(content);
      rethrow;
    }

    return parseInfo.parsebuilder.toString();
  }

  void processPhase3(XUIHtmlBuffer buffer) {
    if (tag == cst.TAG_NO_DOM) {
      // cas des slot
      toChildrenPhase3(buffer);
      return;
    }

    buffer.addTab();
    buffer.html.write('<' + this.tag);

    this.attributes?.entries?.forEach((f) {
      var c = f.value.content;
      var keyAttr = processContent(f.key, ParseInfoMode.KEY);

      if (keyAttr != "" && c != null) {
        if (c is String) {
          var valProp = processContent(c, ParseInfoMode.ATTR);
          bool mustAdd = true;
          bool isBool = false;
          if (c != valProp) {
            // transformation par recherche de tag
            if (valProp == "" || valProp == "false") {
              mustAdd = false; // pas d'ajout si vide ou false
            }
          }
          if (mustAdd) {
            if (valProp == "true" || valProp == "false") {
              isBool = true;
            }
            buffer.html.write(" ");
            buffer.html.write(keyAttr);
            if (!isBool) {
              /// pas d'ajout de valeur si boolean
              buffer.html.write("=");
              isBool
                  ? (buffer.html.write(valProp))
                  : (buffer.html.write('"' + valProp + '"'));
            }
          }
        } else {
          // attribut boolean
          buffer.html.write(" ");
          buffer.html.write(keyAttr);
          buffer.html.write("=");
          buffer.html.write(c);
        }
      } else if (keyAttr != "") {
        // attribut sans valeur (ex  : <v-btn dark>)
        buffer.html.write(" ");
        buffer.html.write(keyAttr);
      }
    });

    buffer.html.write('>');

    bool hasChidren = this.children?.firstWhere(
            (c) => (c is! XUIElementHTMLText),
            orElse: () => null) !=
        null;

    if (hasChidren) buffer.html.write('\n');

    buffer.tab(1);
    toChildrenPhase3(buffer);
    buffer.tab(-1);

    if (hasChidren) buffer.addTab();
    buffer.html.write('</' + this.tag + '>\n');
  }

  void toChildrenPhase3(XUIHtmlBuffer buffer) {
    this.children?.forEach((c) {
      if (c is XUIElementHTMLText) {
        c.content.trim().isNotEmpty ? c.processPhase3(buffer) : null;
      } else {
        (c as XUIElementHTML).processPhase3(buffer);
      }
    });
  }
}

class XUIElementHTMLText extends XUIElementHTML {
  String content;

  @override
  void processPhase3(XUIHtmlBuffer buffer) {
    buffer.html.write(processContent(content, ParseInfoMode.CONTENT));
  }
}

/// provient d'un provider interne
abstract class XUIElementNative extends XUIElementXUI {
  Future<XUIModel> doProcessPhase1(
      XUIEngine engine, XUIElementHTML html) async {
    return Future.value(null);
  }

  Future doProcessPhase2(XUIEngine engine, XUIElementHTML html) async {
    return Future.value();
  }

  void register(XUIResource reader) {
    reader.components[xid] ??= DicoOrdered()..add(XUIComponent(this, MODE_ALL));
  }
}

///  uniquement un text
class XUIElementText extends XUIElementXUI {
  String content;
}

///   provient d'un provider fichier XUI
class XUIElementXUI extends XUIElement {
  String xid;
  String idRessource;
}
