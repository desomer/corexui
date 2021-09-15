import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import '../XUIConfigManager.dart';
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
  String? tag;

  // les attribut XHTML
  HashMap<String, XUIProperty>? attributes;

  // les enfants
  List<XUIElement>? children;

  // les prop xui
  HashMap<String, XUIProperty>? propertiesXUI;

  bool isEmpty() {
    return (attributes == null || attributes?.isEmpty == true) &&
        (children == null || children?.isEmpty == true) &&
        (propertiesXUI == null || propertiesXUI?.isEmpty == true);
  }
}

///***************************************************************
class XUIElementHTML extends XUIElement {
  static XUIElement notElem = XUIElementHTML();
  XUIElementHTML? parent;

  XUIElementXUI? originElemXUI;
  List<XUIComponent>? implementBy;
  List<XUIDesign>? designBy;

  int getNbChildNoText() {
    int nb = 0;
    children?.forEach((c) {
      if (c is! XUIElementHTMLText) {
        nb++;
      }
    });
    return nb;
  }

  XUIElementHTML? firstChildNoText() {
    if (children != null) {
      for (var item in children!) {
        if (item is! XUIElementHTMLText) {
          return item as XUIElementHTML;
        }
      }
    }
    return null;
  }

  ///calcule des propertiesXUI [[Prop]]
  String? calculatePropertyXUI(String? prop, ParseInfo? parseInfoOptional) {
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
      return calculatePropertyXUI(this.originElemXUI!.xid, parseInfo);
    } else if (tag == cst.ATTR_PARENT_XID) {
      // cas du parent XID
      XUIElementHTML p = this.parent as XUIElementHTML;
      // ignore: unnecessary_null_comparison
      while (p != null) {
        if (p.originElemXUI != null && p.originElemXUI!.xid != null) {
          break;
        }
        p = p.parent!;
      }

      return p.calculatePropertyXUI(p.originElemXUI!.xid, parseInfo);
    }

    // gestion de la recherche sur des enfant (@-1) ou les parents (@0+)
    if (tag.contains("@")) {
      var atTag = tag.split("@");
      tag = atTag[0];
      var atScope = atTag[1];
      if (atScope == "-1") {
        return firstChildNoText()!.searchPropertyXUI(tag, 0, parseInfo);
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

    XUIProperty? prop = propertiesXUI == null ? null : propertiesXUI![tag];

    if (prop != null) {
      return _getValueXUIProperty(parseInfo, prop, tag);
    } else if (parent != null && (deep < 0 || deep > 0)) {
      return parent!.searchPropertyXUI(tag, deep - 1, parseInfo);
    }
  }

  /// genere la valeur du la property (et affecte le binding vuej )
  /// tag : tag sans @0+          disabled="[[disabled]]"
  ///                             @click.stop="[[navDrawerBind@0+]] = ![[navDrawerBind@0+]]"
  ///
  dynamic _getValueXUIProperty(
      ParseInfo parseInfo, XUIProperty prop, String tag) {
    //---------------------------------------------------
    if (parseInfo.mode == ParseInfoMode.ATTR &&
        parseInfo.context == "class" &&
        (prop.content == true || prop.content == "true")) {
      return tag; // si class  : le class est le tag  class="[[CLASS]]"
    }

    //---------------------------------------------------
    var namespace = "main.";

    if (prop is XUIPropertyBinding) {
      var name = prop.binding;
      int isArray = name!.lastIndexOf("[]");
      if (isArray > 0) {
        var arrayName = name.substring(0, isArray);
        name =
            arrayName.split(".").last + "_item" + name.substring(isArray + 2);
        namespace = "";
      }

      if (parseInfo.mode == ParseInfoMode.CONTENT) {
        // si dans un contenu de tag <div>{{binding}}</div>
        return "{{" + namespace + name + "}}";
      }
      parseInfo.prefix = "v-bind:";
      return namespace + name;
    }

    //---------------------------------------------------
    if (tag.startsWith(":")) {
      //les variables :varItems
      // gestion des v-for
      var numVar = 0;
      if (parseInfo.context == "v-for") {
        numVar = 5 - parseInfo.parsebuilder.toString().split(tag).length;
      }

      var name = prop.content.toString();
      int mapOnArray = name.lastIndexOf("[]"); // gestion de tableau de tableau
      if (mapOnArray > 0) {
        var arrayName = name.substring(0, mapOnArray);
        if (numVar == 1) {
          // attribut variable item du v-for
          name = name.substring(mapOnArray + 3);
        } else if (numVar == 2) {
          // attribut variable idx du v-for
          name = name.substring(mapOnArray + 3);
        } else {
          // attribut simple
          name = arrayName.split(".").last +
              "_item" +
              name.substring(mapOnArray + 2);
        }
        return name;
      } else {
        if (numVar == 1 || numVar == 2) {
          namespace = ""; //pas de namespace sur variable item et idx du v-for
        }

        return namespace + name;
      }
    }
    //---------------------------------------------------
    // sinon retour en directe
    return prop.content;
  }

  /// generation du contenu avec [[]] d'un balise <div>CONTENT<div>
  dynamic _processContentPhase3(XUIEngine engine, ParseInfo parseInfo) {
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
      XUIConfigManager.printc("pb parse $e $s");
      XUIConfigManager.printc(parseInfo.parsebuilder.toString());
      rethrow;
    }

    return parseInfo.parsebuilder.toString();
  }

  /// gestion de la phase 3 : generation de l'HTML
  void processPhase3(XUIEngine engine, XUIHtmlBuffer buffer) {
    var oldBuf;

    // gestion to JSON
    if (_hasPropConvertJSON()) {
      oldBuf = buffer;
      buffer = XUIHtmlBuffer();
    }

    // gestion du xui-if
    if (hasPropXUIIF() && !isXUIIF(engine)) {
      // xui-if a false
      return;
    }

    if (tag == cst.TAG_NO_DOM || tag == TAG_RELOADER) {
      // cas des slot ou des reloader
      bool isReloader = false;
      bool isRoot = buffer.html.isEmpty;
      bool hasTagReloader = (tag == TAG_RELOADER) ||
          (this.propertiesXUI != null &&
              this.propertiesXUI!.containsKey(ATTR_RELOADER));

      if (!XUIConfigManager.reloaderEnable) {
        hasTagReloader = false;
      }

      if (!isRoot && engine.isModeDesign() && hasTagReloader) {
        isReloader = true;
        doAddReloaderPhase3(engine, buffer);
      }

      buffer.trim = (this.propertiesXUI != null &&
          this.propertiesXUI!.containsKey(ATTR_TRIM_CONTENT));

      if (!isReloader) {
        // gestion des no-dom

        doChildrenPhase3(engine, buffer);
      }
      // pas de tag hmtl ajouté dans la page
      return;
    }

    buffer.addTab();
    buffer.html.write('<' + this.tag!);

    // gestion des attributs
    doAttributPhase3(engine, buffer);

    buffer.html.write('>');

    XUIElement? hc = children?.firstWhere((c) => (c is! XUIElementHTMLText),
        orElse: () => notElem);

    bool hasChildrenNoText = hc != null && hc != notElem;

    if (hasChildrenNoText) buffer.html.write('\n');

    buffer.tab(1);
    doChildrenPhase3(engine, buffer);
    buffer.tab(-1);

    // if (this.tag=="script")
    // {
    //   print("script************************");
    // }

    // var b = buffer.html.toString();

    // if (true || (hasChildren && b.lastIndexOf("   ")>0))
    // {
    //   print("tab "+buffer.idxTab.toString());
    //   buffer.tab(-2);
    //  // buffer.addTab();
    //   buffer.tab(2);
    // }

    if (hasChildrenNoText) {
      buffer.addTab();
    }
    buffer.html.write('</' + this.tag! + '>\n');

    if (oldBuf != null) {
      oldBuf.html.write(json.encode(buffer.html.toString()));
    }
  }

  bool isXUIIF(cst.XUIEngine engine) {
    var ifContent = this.propertiesXUI![ATTR_XUI_IF]!.content;
    ParseInfo parseInfo = ParseInfo(ifContent, null, ParseInfoMode.ATTR);
    var valIf = _processContentPhase3(engine, parseInfo);
    if (valIf == "" || valIf == "false") {
      // xui-if a false
      return false;
    }
    return true;
  }

  bool hasPropXUIIF() {
    return this.propertiesXUI != null &&
        this.propertiesXUI!.containsKey(ATTR_XUI_IF);
  }

  bool _hasPropConvertJSON() {
    return this.propertiesXUI != null &&
        this.propertiesXUI!.containsKey(ATTR_CONVERT_JSON);
  }

  String getForVar() {
    if (this.propertiesXUI != null &&
        this.propertiesXUI!.containsKey(ATTR_XUI_FORVAR)) {
      return this.propertiesXUI![ATTR_XUI_FORVAR]!.content;
    } else {
      return "nb";
    }
  }

  void doAddReloaderPhase3(cst.XUIEngine engine, XUIHtmlBuffer buffer) {
    var xid = this.originElemXUI!.xid;
    ParseInfo parseInfo = ParseInfo(xid, null, ParseInfoMode.ATTR);
    var xidCal = _processContentPhase3(engine, parseInfo);
    var modeDisplay = "contents";
    if (this.propertiesXUI![ATTR_MODE_DISPLAY] != null) {
      modeDisplay = this.propertiesXUI![ATTR_MODE_DISPLAY]!.content.toString();
    }
    buffer.html.write("<v-xui-reloader modedisplay=\"" +
        modeDisplay +
        "\" partid=\"" +
        xidCal +
        "\"></v-xui-reloader>");
  }

  void doAttributPhase3(cst.XUIEngine engine, XUIHtmlBuffer buffer) {
    this.attributes?.entries.forEach((f) {
      var contentAttr = f.value.content;
      var attrName = f.key;
//print("*******************"+ f.key);
      ParseInfo parseInfo = ParseInfo(attrName, null, ParseInfoMode.KEY);
      String keyAttr = _processContentPhase3(engine, parseInfo);

      if (keyAttr.startsWith("if:")) {
        var listArg = keyAttr.split(":");
        if (listArg[1]=="")
        {
           //la condition est vide 
           return;
        }
        keyAttr = listArg[2];
      }

      if (attrName.startsWith("[[event")) {
        print("******************* event > " + keyAttr);
        XUIElementHTML elem = this;
        if (attrName == "[[event@-1]]") {
          elem = firstChildNoText()!;
        }

        elem.propertiesXUI?.forEach((key, value) {
          if (key.startsWith("@")) {
            print("******************* event prop id=" +
                key +
                "=>" +
                value.content.toString());
            buffer.html.write(" " +
                key +
                "=\"\$mth('" +
                value.content +
                "', ...arguments)\"");
          }
        });
        return;
      }

      var valProp = contentAttr;

      if (keyAttr != "" && contentAttr != null) {
        if (contentAttr is String) {
          ParseInfo parseInfo =
              ParseInfo(contentAttr, keyAttr, ParseInfoMode.ATTR);

          String valProp = _processContentPhase3(engine, parseInfo);
          bool mustAdd = true;
          bool isBool = false;
          //-----------------------------------------------------------------------------------
          if (contentAttr != valProp) {
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
              var listArg = valProp.split(";");
              var val = StringBuffer();
              for (var i = 0; i < listArg.length; i++) {
                var v = listArg[i].trim();
                if (!v.endsWith(":")) {
                  if (val.isNotEmpty) {
                    val.write(";");
                  }
                  val.write(v);
                }
              }
              valProp = val.toString();
            }

            // transformation par recherche de tag
            if (valProp == "" || valProp == "false") {
              mustAdd = false; // pas d'ajout si vide ou false
            }

            if (parseInfo.prefix != null) {
              mustAdd = true;
              // binding
              if (!keyAttr.startsWith("@") && keyAttr != "v-model") {
                keyAttr = parseInfo.prefix! + keyAttr;
              }
            }
          }
          //-----------------------------------------------------------------------------------
          if (mustAdd) {
            // cas du :value="false"   =>  reste en chaine "" pour vuejs sinon en boolean
            if ((valProp == "true" || valProp == "false") &&
                !(keyAttr.startsWith(":") || keyAttr.startsWith("v-bind:"))) {
              isBool = true;
            }

            buffer.html.write(" ");
            buffer.html.write(keyAttr);

            if (!isBool) {
              /// pas d'ajout de valeur si boolean   exemple : dark="true" donne dark
              buffer.html.write("=");
              buffer.html.write('"' + valProp + '"');
            }

            // analyse des attribut avec du binding
            //engine.dataBindingInfo.parseAttr(this, keyAttr, valProp.toString());
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
  }

  void doChildrenPhase3(XUIEngine engine, XUIHtmlBuffer buffer) {
    this.children?.forEach((c) {
      (c as XUIElementHTML).processPhase3(engine, buffer);

      // if (c is XUIElementHTMLText) {
      //       c.processPhase3(engine, buffer);
      // } else {
      //   (c as XUIElementHTML).processPhase3(engine, buffer);
      // }
    });
  }
}

class XUIElementHTMLText extends XUIElementHTML {
  StringBuffer? content;

  @override
  void processPhase3(XUIEngine engine, XUIHtmlBuffer buffer) {
    ParseInfo parseInfo = ParseInfo(content, null, ParseInfoMode.CONTENT);

    if (this.content == null) {
      return;
    }
    var c = this.content.toString();
    var cTrim = c.trimRight();
    if (cTrim.isEmpty) {
      return;
    }

    var cont = _processContentPhase3(engine, parseInfo);

    // analyse des attribut avec du binding
    //engine.dataBindingInfo.parseContent(this, cont);

    if (buffer.trim) {
      buffer.trim = false;
      cont = cTrim;
      // print("trim <"+cont+">");
      // cont= cont.toString().trimRight();
      if (cTrim.endsWith(";")) {
        cont = cTrim + "\n";
      }
      // print("result <"+cont+">");
    }
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
    reader.components[xid!] ??= DicoOrdered()
      ..add(XUIComponent(this, MODE_ALL));
  }
}

///***************************************************************
///   provient d'un provider fichier XUI
class XUIElementXUI extends XUIElement {
  String? xid;
  String? idRessource;
}

///
///  uniquement un text
class XUIElementText extends XUIElementXUI {
  late StringBuffer content;
}
