import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import '../XUIEngine.dart' as cst;
import '../XUIEngine.dart';
import '../XUIFactory.dart';
import 'XUIProperty.dart';

/// element racine des   XUIElementXUI, XUIElementText
///   et des version HTML :   XUIElementHTML, XUIElementHTMLText
///       ces derniere ont une methode processPhase3 de generation de l'HTML
///
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

  XUIElementXUI originElemXUI;
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

  ///calcule des propertiesXUI [[Prop]]
  String calculatePropertyXUI(String prop) {
    if (prop != null) {
      ParseInfo parseInfo = ParseInfo(prop, ParseInfoMode.PROP);
      XUIProperty.parse(parseInfo, (String tag) {
        var ret = searchPropertyXUI(tag, -1);
        return ret != null ? ret : doPropPlaceHolder(tag);
      });
      prop = parseInfo.parsebuilder.toString();
    }

    return prop;
  }

  String doPropPlaceHolder(String tag) {
    // gestion du placeholder
    int idx = tag.indexOf("@");
    if (idx > 0) {
      tag = tag.substring(0, idx);
    }
    return "[" + tag + "]";
  }

  dynamic searchPropertyXUI(String tag, int deep) {
    if (tag == cst.ATTR_XID) {
      // ne cherche pas sur les parent
      return calculatePropertyXUI(this.originElemXUI.xid);
    } else if (tag == cst.ATTR_PARENT_XID) {
      XUIElementHTML p = this.parent;
      while (p != null) {
        if (p.originElemXUI != null && p.originElemXUI.xid != null) {
          break;
        }
        p = p.parent;
      }

      return p.calculatePropertyXUI(p.originElemXUI.xid);
    }

    /// gestion de la recherche sur des enfant (@-1) ou les parents (@0+)
    if (tag.contains("@")) {
      var atTag = tag.split("@");
      tag = atTag[0];
      var atScope = atTag[1];
      if (atScope == "-1") {
        return firstChildNoText().searchPropertyXUI(tag, 0);
      }
      if (atScope == "0+") {
        return searchPropertyXUI(tag, -2);
      }
      int scope = int.tryParse(atScope) ?? 0;
      return searchPropertyXUI(tag, scope);
    } else if (deep == -1) {
      // par defaut uniquement dans himself (@0)
      deep = 0;
    }

    XUIProperty prop = propertiesXUI == null ? null : propertiesXUI[tag];
    if (prop != null) {
      return prop.content;
    } else if (parent != null && (deep < 0 || deep > 0)) {
      return parent.searchPropertyXUI(tag, deep - 1);
    }
  }

  /// generation du contenu avec [[]] d'un balise <div>CONTENT<div>
  dynamic processContent(XUIEngine engine, String content, ParseInfoMode mode) {
    ParseInfo parseInfo = ParseInfo(content, mode);
    try {
      XUIProperty.parse(parseInfo, (String tag) {
        var ret = searchPropertyXUI(tag, -1);

        return ret != null
            ? ret
            : ((mode == ParseInfoMode.CONTENT ? (doPropPlaceHolder(tag)) : ""));
      });
    } catch (e, s) {
      print("pb parse $e $s");
      print(content);
      rethrow;
    }

    return parseInfo.parsebuilder.toString();
  }

  /// gestion de la phase 3 : generation de l'HTML
  void processPhase3(XUIEngine engine, XUIHtmlBuffer buffer) {
    var oldBuf;

    if (this.propertiesXUI != null &&
        this.propertiesXUI.containsKey(ATTR_CONVERT_JSON)) {
      oldBuf = buffer;
      buffer = XUIHtmlBuffer();
    }

    if (tag == cst.TAG_NO_DOM || tag==TAG_RELOADER) {
      // cas des slot ou des reloader
      bool isReloader = false;
      bool isRoot = buffer.html.isEmpty;
      bool hasTagReloader = (tag==TAG_RELOADER) || ( this.propertiesXUI != null &&
          this.propertiesXUI.containsKey(ATTR_RELOADER));

      if (!isRoot && engine.isModeDesign() && hasTagReloader) {
        isReloader = true;
        var xid = this.originElemXUI.xid;
        var xidCal = processContent(engine, xid, ParseInfoMode.ATTR);
         var modeDisplay = "unset";
        if (this.propertiesXUI[ATTR_MODE_DISPLAY]!=null)
        {
            modeDisplay=this.propertiesXUI[ATTR_MODE_DISPLAY]?.content.toString();
        }
        buffer.html.write(
            "<v-xui-reloader modedisplay=\"" + modeDisplay + "\" partid=\"" + xidCal + "\"></v-xui-reloader>");
      }

      if (!isReloader) {
        toChildrenPhase3(engine, buffer);
      }
      return;
    }

    if (this.propertiesXUI != null && this.propertiesXUI.containsKey("if"))
    {
        var valIf = processContent(engine, this.propertiesXUI["if"].content, ParseInfoMode.ATTR);
        if (valIf != "true")
        {
            return;
        }
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
            //supprime les balise class et style faussement non vide
            if (keyAttr == "class") {
              valProp = valProp.toString().trim();
            }
            if (keyAttr == "style") {
              valProp = valProp.toString().trim();
              if (valProp==";" || valProp==";;")
              {
                 valProp="";
              }
            }

            // transformation par recherche de tag
            if (valProp == "" || valProp == "false") {
              mustAdd = false; // pas d'ajout si vide ou false
            }
          }
          if (mustAdd) {
            // cas du :value="false"   =>  reste en chaine "" pour vuejs sinon en boolean
            if ((valProp == "true" || valProp == "false") &&
                !(keyAttr.startsWith(":"))) {
              isBool = true;
            }
            buffer.html.write(" ");

            // // gestion des - devant des attr pour bypasser les correcteurs de syntaxe de vscode -style="[[xxx]]"
            // if (keyAttr.toString().startsWith("-")) {
            //   keyAttr = keyAttr.toString().substring(1);
            // }

            buffer.html.write(keyAttr);

            if (!isBool) {
              /// pas d'ajout de valeur si boolean   exemple : dark="true" donne dark
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

    if (oldBuf != null) {
      oldBuf.html.write(json.encode(buffer.html.toString()));
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
///   provient d'un provider fichier XUI
class XUIElementXUI extends XUIElement {
  String xid;
  String idRessource;
}

///
///  uniquement un text
class XUIElementText extends XUIElementXUI {
  String content;
}
