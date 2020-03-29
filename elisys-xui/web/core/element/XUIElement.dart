import 'dart:async';
import 'dart:collection';
import 'dart:convert';
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

///***************************************************************
class XUIElementHTML extends XUIElement {
  XUIElementHTML parent;

  XUIElementXUI origin;
  List<XUIComponent> implementBy;
  List<XUIDesign> designBy;

  int getNbChildNoText() {
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

  String calculateProp(String prop) {
    if (prop != null) {
      ParseInfo parseInfo = ParseInfo(prop, ParseInfoMode.PROP);
      XUIProperty.parse(parseInfo, (String tag) {
        var ret = searchPropertyXUI(tag, -1);
        return ret != null ? ret : "[" + tag + "]";
      });
      prop = parseInfo.parsebuilder.toString();
    }

    return prop;
  }

  dynamic searchPropertyXUI(String tag, int deep) {
    if (tag == cst.ATTR_XID) {
      return calculateProp(this.origin.xid);
    }

    if (tag.contains("@")) {
      var atTag = tag.split("@");
      tag = atTag[0];
      var atHtml = atTag[1];
      if (atHtml == "-1") {
        return firstChildNoText().searchPropertyXUI(tag, 0);
      }
      if (atHtml == "0") {
        return searchPropertyXUI(tag, 0);
      }
    }

    XUIProperty prop = propertiesXUI == null ? null : propertiesXUI[tag];
    if (prop != null) {
      return prop.content;
    } else if (parent != null && (deep < 0 || deep > 0)) {
      return parent.searchPropertyXUI(tag, deep - 1);
    }
  }

  dynamic processContent(XUIEngine engine, String content, ParseInfoMode mode) {
    ParseInfo parseInfo = ParseInfo(content, mode);
    try {
      XUIProperty.parse(parseInfo, (String tag) {
        var ret = searchPropertyXUI(tag, -1);
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

  void processPhase3(XUIEngine engine, XUIHtmlBuffer buffer) {
    var oldBuf;

    if (this.propertiesXUI!=null && this.propertiesXUI.containsKey("convert-json"))
    {
      oldBuf = buffer;
      buffer= XUIHtmlBuffer();
    }

    if (tag == cst.TAG_NO_DOM) {
      // cas des slot
      bool isReloader = false;
      bool isRoot = buffer.html.isEmpty;
      if (!isRoot && engine.isModeDesign() && this.propertiesXUI!=null && this.propertiesXUI.containsKey(ATTR_RELOADER))
      { 
        isReloader=true;
        var xid = processContent(engine, this.origin.xid, ParseInfoMode.ATTR);
        buffer.html.write("<v-xui-reloader partid=\""+xid+"\"></v-xui-reloader>");
      }

      if (!isReloader) {
        toChildrenPhase3(engine, buffer);
      }
      return;
    }

    buffer.addTab();
    buffer.html.write('<' + this.tag);

    this.attributes?.entries?.forEach((f) {
      var c = f.value.content;
      String keyAttr = processContent(engine, f.key, ParseInfoMode.KEY);
      var valProp = c;
      if (keyAttr != "" && c != null) {
        if (c is String) {
          valProp = processContent(engine, c, ParseInfoMode.ATTR);
          bool mustAdd = true;
          bool isBool = false;
          if (c != valProp) {
            // transformation par recherche de tag
            if (valProp == "" || valProp == "false") {
              mustAdd = false; // pas d'ajout si vide ou false
            }
          }
          if (mustAdd) {
            // cas du :value="false"
            if ((valProp == "true" || valProp == "false") && !(keyAttr.startsWith(":")) ) {
              isBool = true;
            }
            buffer.html.write(" ");
            if (keyAttr.toString().startsWith("-")) {
              keyAttr = keyAttr.toString().substring(1);
              // gestion des - devant des attr pour bypasser les correcteurs de syntaxe de vscode -style="[[xxx]]"  
            } 

            buffer.html.write(keyAttr);
            
            if (!isBool) {
              /// pas d'ajout de valeur si boolean
              buffer.html.write("=");
              isBool
                  ? (buffer.html.write(valProp))
                  : (buffer.html.write('"' + valProp + '"'));
            }

            engine.dataBindingInfo.parseAttr(this, keyAttr, valProp.toString());

          }
        } else {
          // attribut boolean
          buffer.html.write(" ");
          buffer.html.write(keyAttr);
          buffer.html.write("=");
          buffer.html.write(valProp);
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
    toChildrenPhase3(engine, buffer);
    buffer.tab(-1);

    if (hasChidren) buffer.addTab();
    buffer.html.write('</' + this.tag + '>\n');

    if (oldBuf!=null)
    {
        oldBuf.html.write( json.encode(   buffer.html.toString()  ));
    }

  }

  void toChildrenPhase3(XUIEngine engine, XUIHtmlBuffer buffer) {
    this.children?.forEach((c) {
      if (c is XUIElementHTMLText) {
        c.content.trim().isNotEmpty ? c.processPhase3(engine, buffer) : null;
      } else {
        (c as XUIElementHTML).processPhase3(engine, buffer);
      }
    });
  }
}

class XUIElementHTMLText extends XUIElementHTML {
  String content;

  @override
  void processPhase3(XUIEngine engine, XUIHtmlBuffer buffer) {
    var cont = processContent(engine, content, ParseInfoMode.CONTENT);
    engine.dataBindingInfo.parseContent(this, cont);
    buffer.html.write(cont);
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

///***************************************************************
///
///  uniquement un text
class XUIElementText extends XUIElementXUI {
  String content;
}

///   provient d'un provider fichier XUI
class XUIElementXUI extends XUIElement {
  String xid;
  String idRessource;
}
