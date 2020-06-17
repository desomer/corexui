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
  String calculatePropertyXUI(String prop, ParseInfo parseInfoOptional) {
    if (prop != null) {
      ParseInfo parseInf;
      if (parseInfoOptional != null) {
        parseInf =
            ParseInfo(prop, parseInfoOptional.context, ParseInfoMode.PROP);
      } else {
        parseInf = ParseInfo(prop, null, ParseInfoMode.PROP);
      }

      XUIProperty.parse(parseInf, (String tag) {
        var ret = searchPropertyXUI(tag, -1, parseInf);
        return ret != null ? ret : doPropPlaceHolder(tag);
      });
      prop = parseInf.parsebuilder.toString();
    }

    return prop;
  }

  String doPropPlaceHolder(String tag) {
    // gestion du placeholder pour les CONTENT (ex : XUI-TITLE)
    int idx = tag.indexOf("@");
    if (idx > 0) {
      tag = tag.substring(0, idx);
    }
    return "[" + tag + "]";
  }

  dynamic searchPropertyXUI(String tag, int deep, ParseInfo parseInfo) {
    if (tag == cst.ATTR_XID) {
      // ne cherche pas sur les parent
      return calculatePropertyXUI(this.originElemXUI.xid, parseInfo);
    } else if (tag == cst.ATTR_PARENT_XID) {
      // cas du parent XID
      XUIElementHTML p = this.parent;
      while (p != null) {
        if (p.originElemXUI != null && p.originElemXUI.xid != null) {
          break;
        }
        p = p.parent;
      }

      return p.calculatePropertyXUI(p.originElemXUI.xid, parseInfo);
    }

    /// gestion de la recherche sur des enfant (@-1) ou les parents (@0+)
    if (tag.contains("@")) {
      var atTag = tag.split("@");
      tag = atTag[0];
      var atScope = atTag[1];
      if (atScope == "-1") {
        return firstChildNoText().searchPropertyXUI(tag, 0, parseInfo);
      }
      if (atScope == "0+") {
        return searchPropertyXUI(tag, -2, parseInfo);
      }
      int scope = int.tryParse(atScope) ?? 0;
      return searchPropertyXUI(tag, scope, parseInfo);
    } else if (deep == -1) {
      // par defaut uniquement dans himself (@0)
      deep = 0;
    }

    XUIProperty prop = propertiesXUI == null ? null : propertiesXUI[tag];

    if (prop != null) {
      if (parseInfo.mode == ParseInfoMode.ATTR &&
          parseInfo.context == "class" &&
          (prop.content == true || prop.content == "true")) {
        return tag;
      }

      return prop.content;
    } else if (parent != null && (deep < 0 || deep > 0)) {
      return parent.searchPropertyXUI(tag, deep - 1, parseInfo);
    }
  }

  /// generation du contenu avec [[]] d'un balise <div>CONTENT<div>
  dynamic processContent(XUIEngine engine, ParseInfo parseInfo) {
    try {
      XUIProperty.parse(parseInfo, (String tag) {
        var ret = searchPropertyXUI(tag, -1, parseInfo);

        return ret != null
            ? ret
            : ((parseInfo.mode == ParseInfoMode.CONTENT
                ? (doPropPlaceHolder(tag))
                : ""));
      });
    } catch (e, s) {
      print("pb parse $e $s");
      print(parseInfo.parsebuilder.toString());
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

    // gestion du xui-if
    if (this.propertiesXUI != null &&
        this.propertiesXUI.containsKey(ATTR_XUI_IF)) {
      ParseInfo parseInfo = ParseInfo(
          this.propertiesXUI[ATTR_XUI_IF].content, null, ParseInfoMode.ATTR);
      var valIf = processContent(engine, parseInfo);
      if (valIf == "" || valIf == "false") {
        return;
      }
    }

    if (tag == cst.TAG_NO_DOM || tag == TAG_RELOADER) {
      // cas des slot ou des reloader
      bool isReloader = false;
      bool isRoot = buffer.html.isEmpty;
      bool hasTagReloader = (tag == TAG_RELOADER) ||
          (this.propertiesXUI != null &&
              this.propertiesXUI.containsKey(ATTR_RELOADER));

      if (!isRoot && engine.isModeDesign() && hasTagReloader) {
        isReloader = true;
        var xid = this.originElemXUI.xid;
        ParseInfo parseInfo = ParseInfo(xid, null, ParseInfoMode.ATTR);
        var xidCal = processContent(engine, parseInfo);
        var modeDisplay = "contents";
        if (this.propertiesXUI[ATTR_MODE_DISPLAY] != null) {
          modeDisplay =
              this.propertiesXUI[ATTR_MODE_DISPLAY]?.content.toString();
        }
        buffer.html.write("<v-xui-reloader modedisplay=\"" +
            modeDisplay +
            "\" partid=\"" +
            xidCal +
            "\"></v-xui-reloader>");
      }

      if (!isReloader) {
        toChildrenPhase3(engine, buffer);
      }
      // pas de tag hmtl ajouté dans la page
      return;
    }

    buffer.addTab();
    buffer.html.write('<' + this.tag);

    // gestion des attributs
    this.attributes?.entries?.forEach((f) {
      var c = f.value.content;
      ParseInfo parseInfo = ParseInfo(f.key, null, ParseInfoMode.KEY);

      String keyAttr = processContent(engine, parseInfo);
      var valProp = c;

      if (keyAttr != "" && c != null) {
        if (c is String) {
          ParseInfo parseInfo;
          if (keyAttr == "class") {
            parseInfo = ParseInfo(c, keyAttr, ParseInfoMode.ATTR);
          } else {
            parseInfo = ParseInfo(c, keyAttr, ParseInfoMode.ATTR);
          }

          valProp = processContent(engine, parseInfo);
          bool mustAdd = true;
          bool isBool = false;

          if (c != valProp) {
            // si dynamique
            //supprime les balise class et style faussement non vide
            if (keyAttr == "class") {
              valProp = valProp.toString().trim();
            }
            if (keyAttr == "style") {
              valProp = valProp.toString().trim();
              // mieux gerer : decoupe split ';'  et controle 'color:;' ne pas mettre color
              if (valProp == ";" || valProp == ";;") {
                valProp = "";
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

            buffer.html.write(keyAttr);

            if (!isBool) {
              /// pas d'ajout de valeur si boolean   exemple : dark="true" donne dark
              buffer.html.write("=");
              buffer.html.write('"' + valProp + '"');
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
    ParseInfo parseInfo = ParseInfo(content, null, ParseInfoMode.CONTENT);
    var cont = processContent(engine, parseInfo);
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
