// ignore_for_file: file_names

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import '../XUIConfigManager.dart';
import '../XUIEngine.dart' as cst;
import '../XUIEngine.dart';
import '../XUIFactory.dart';
import '../XUIJSInterface.dart';
import 'XUIProperty.dart';


/// element racine des   XUIElementXUI, XUIElementText
///   et des version HTML :   XUIElementHTML, XUIElementHTMLText
///       ces derniere ont une methode processPhase3 de generation de l'HTML
///
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


  bool canSurround(FileDesignInfo fileInfo)
  {
     var inLocalStorage = "localStorage";
     var idRessource = (this.originElemXUI?.idRessource ?? inLocalStorage);  
     print("fffffffffffffffffff "+fileInfo.file);
     return idRessource==inLocalStorage || idRessource=="app/frame0Empty.html" || idRessource==fileInfo.file;
  }

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
      for (final item in children!) {
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
        final String? ret = searchPropertyXUI(tag, -1, parseInf) as String?;
        return ret ?? doPropPlaceHolder(tag, parseInf);
      });
      // ignore: parameter_assignments
      prop = parseInf.parsebuilder.toString();
    }

    return prop;
  }

  String doPropPlaceHolder(String tag, ParseInfo? parseInfoOptional) {
    // gestion du placeholder pour les CONTENT (ex : XUI-TITLE)
    final int idx = tag.indexOf("@");
    if (idx > 0) {
      // ignore: parameter_assignments
      tag = tag.substring(0, idx);
    }

    if (parseInfoOptional?.tagPrefix=="zero")
      return "0";
      
    return "[$tag]";
  }

  dynamic searchPropertyXUI(String tag, int deep, ParseInfo parseInfo) {
    if (tag == cst.ATTR_XID) {
      // ne cherche pas sur les parent
      return calculatePropertyXUI(originElemXUI!.xid, parseInfo);
    } else if (tag == cst.ATTR_PARENT_XID) {
      // cas du parent XID
      XUIElementHTML? p = parent;

      while (p != null) {
        if (p.originElemXUI != null && p.originElemXUI!.xid != null) {
          break;
        }
        p = p.parent;
      }

      return p!.calculatePropertyXUI(p.originElemXUI!.xid, parseInfo);
    }

    if (tag.contains("|")) {
        final atTag = tag.split("|");
        tag = atTag[0];
        parseInfo.orTag=atTag[1];
    }

    // gestion de la recherche sur des enfant (@-1) ou les parents (@0+)
    if (tag.contains("@")) {
      final atTag = tag.split("@");
      // ignore: parameter_assignments
      tag = atTag[0];
      final atScope = atTag[1];
      if (atScope == "-1") {
        return firstChildNoText()!.searchPropertyXUI(tag, 0, parseInfo);
      }
      else if (atScope == "-2") {
        return firstChildNoText()!.firstChildNoText()!.searchPropertyXUI(tag, 0, parseInfo);
      }
      else if (atScope == "-3") {
        return firstChildNoText()!.firstChildNoText()!.firstChildNoText()!.searchPropertyXUI(tag, 0, parseInfo);
      }
      else if (atScope == "0+") {
        return searchPropertyXUI(tag, -2, parseInfo);
      }
      else if (atScope == "1+") {
        if (parent!=null) {
          return parent!.searchPropertyXUI(tag, -2, parseInfo);
        } else {
          return null;
        }
      }

      final int scope = int.tryParse(atScope) ?? 0;
      return searchPropertyXUI(tag, scope, parseInfo);
    } else if (deep == -1) {
      // par defaut uniquement dans himself (@0)
      // ignore: parameter_assignments
      deep = 0;
    }

    if (tag.startsWith("index:"))
    {
      tag=tag.substring(6);
      parseInfo.tagPrefix="index";
    }
    if (tag.startsWith("item:"))
    {
      tag=tag.substring(5);
      parseInfo.tagPrefix="item";
    }

    if (tag.startsWith("zero:"))
    {
      tag=tag.substring(5);
      parseInfo.tagPrefix="zero";
    }

    final XUIProperty? prop = propertiesXUI == null ? null : propertiesXUI![tag];

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
  dynamic _getValueXUIProperty(ParseInfo parseInfo, XUIProperty prop, String tag) {
    //---------------------------------------------------
    if (parseInfo.mode == ParseInfoMode.ATTR &&
        parseInfo.context == "class" &&
        (prop.content == true || prop.content == "true")) {
      return tag; // si class  : le class est le tag  class="[[CLASS]]"
    }

    //---------------------------------------------------
    var namespace = "main.";

    if (prop is XUIPropertyBinding) {
      
      var name = prop.binding!;
      int isArray = name.lastIndexOf("[]");
      if (isArray<=0) {
          String? varitems = searchPropertyXUI(PROP_VAR_ITEMS+"@1+", 0, parseInfo) as String?;
          if (varitems!=null)
          {
            varitems=varitems.substring(varitems.indexOf(".")+1);  // retrait du scope
            name= "$varitems[].$name";
            isArray = name.lastIndexOf("[]");
            //prop.cacheBinding=name;
            // ignore: avoid_print
            //print("-------------- varitems map --------------> $name");
          }
      }
      
      if (isArray > 0) {
        final arrayName = name.substring(0, isArray);
        name = "${arrayName.split(".").last}_item${name.substring(isArray + 2)}";
        namespace = "";
      }
      else
      {
        String? varNameSpace = searchPropertyXUI("varnamespace@1+", 0, parseInfo) as String?;
        if (varNameSpace!=null)
            namespace=varNameSpace+".";
        prop.namespace=varNameSpace;
      }

      
      if (parseInfo.mode == ParseInfoMode.CONTENT) {
        // si dans un contenu de tag <div>{{binding}}</div>
        return "{{$namespace$name}}";
      }
      parseInfo.prefix = "v-bind:";
      return namespace + name;
    }


    //print("tag "+ tag);
    //---------------------------------------------------
  
    if (tag.startsWith(":")) {
      //les variables :varItems
      // gestion des v-for
      var numVar = 0;
      if (parseInfo.context == "v-for") {
        numVar = 5 - parseInfo.parsebuilder.toString().split(tag).length; 
      }

      if (parseInfo.tagPrefix=="index")   // pour les for
      {
        numVar=2;
      }
      if (parseInfo.tagPrefix=="item")  // pour les treeview et le datatable
      {
        numVar=1;
      }

      var name = prop.content.toString();
      final int mapOnArray = name.lastIndexOf("[]"); // gestion de TABLEAU de TABLEAU
      if (mapOnArray > 0) {
        final arrayName = name.substring(0, mapOnArray);
        if (numVar == 1) {
          // attribut variable item du v-for
          name = name.substring(mapOnArray + 3);
        } else if (numVar == 2) {
          // attribut variable idx du v-for
          name = name.substring(mapOnArray + 3);
        } else {
          // attribut simple
          name = "${arrayName.split(".").last}_item${name.substring(mapOnArray + 2)}";
        }
        return name;
      } else {

        if (numVar == 1 || numVar == 2) {
          namespace = ""; //pas de namespace sur variable item et idx du v-for
        }
        else
        {
          String? varNameSpace = searchPropertyXUI("varnamespace@1+", 0, parseInfo) as String?;
          if (varNameSpace!=null)
              namespace=varNameSpace+".";
        }

        // if (numVar == 3) {
        //   // affecte la variable de for pour afficher le designer
        //   this.propertiesXUI![PROP_FOR_VAR]=new XUIProperty(name);
        // }

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
        if (ret==null && parseInfo.orTag!=null)
        {
          var t = parseInfo.orTag!;
          parseInfo.orTag=null;
          ret = searchPropertyXUI(t, -1, parseInfo);
        }

        return ret ?? (parseInfo.mode == ParseInfoMode.CONTENT ? doPropPlaceHolder(tag, parseInfo): "");
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
    XUIHtmlBuffer? oldBuf;

    // gestion to JSON
    if (_hasPropConvertJSON()) {
      oldBuf = buffer;
      // ignore: parameter_assignments
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
      final bool isRoot = buffer.html.isEmpty;
      bool hasTagReloader = (tag == TAG_RELOADER) ||
          (propertiesXUI != null && propertiesXUI!.containsKey(ATTR_RELOADER));

      if (!XUIConfigManager.reloaderEnable) {
        hasTagReloader = false;
      }

      if (!isRoot && engine.isModeDesign() && hasTagReloader) {
        var parseInfo = ParseInfo("", null, ParseInfoMode.PROP);
        // pas de reloader si dans un v-for (manque le passage de l'item au composant xui-reloader) 
        String? varitems = searchPropertyXUI(PROP_VAR_ITEMS+"@2", 0, parseInfo) as String?;
        if (varitems==null)
        {
          isReloader = true;
          _doAddReloaderPhase3(engine, buffer);
        }
      }

      buffer.trim = propertiesXUI != null && propertiesXUI!.containsKey(ATTR_TRIM_CONTENT);

      if (!isReloader) {
        // gestion des no-dom
        _doChildrenPhase3(engine, buffer);
      }
      // pas de tag hmtl ajouté dans la page
      return;
    }

    buffer.addTab();
    buffer.html.write('<${tag!}');

    // gestion des attributs
    _doAttributPhase3(engine, buffer);

    buffer.html.write('>');

    final XUIElement? hc = children?.firstWhere((c) => c is! XUIElementHTMLText, orElse: () => notElem);

    final bool hasChildrenNoText = hc != null && hc != notElem;
    
    if (hasChildrenNoText) buffer.html.write('\n');

    buffer.tab(1);
    _doChildrenPhase3(engine, buffer);
    buffer.tab(-1);

    if (hasChildrenNoText) {
      buffer.addTab();
    }
    buffer.html.write('</${tag!}>\n');

    if (oldBuf != null) {
      oldBuf.html.write(json.encode(buffer.html.toString()));
    }
  }

  /////////////////////////////////////////////////////////////////////////////////////////////

  void _doAddReloaderPhase3(cst.XUIEngine engine, XUIHtmlBuffer buffer) {
    final xid = originElemXUI!.xid;
    final ParseInfo parseInfo = ParseInfo(xid, null, ParseInfoMode.ATTR);
    final String xidCal = _processContentPhase3(engine, parseInfo) as String;
    var modeDisplay = "contents";
    if (propertiesXUI![ATTR_MODE_DISPLAY] != null) {
      modeDisplay = propertiesXUI![ATTR_MODE_DISPLAY]!.content.toString();
    }
    buffer.html.write('<v-xui-reloader modedisplay="$modeDisplay" partid="$xidCal"></v-xui-reloader>');  
  }


  void _doAttributPhase3(cst.XUIEngine engine, XUIHtmlBuffer buffer) {
    // ignore: avoid_function_literals_in_foreach_calls
    attributes?.entries.forEach((f) {
      final contentAttr = f.value.content;
      final attrName = f.key;
      //print("*******************"+ f.key);
      final ParseInfo parseInfo = ParseInfo(attrName, null, ParseInfoMode.KEY);
      String keyAttr = _processContentPhase3(engine, parseInfo) as String;

      if (keyAttr.startsWith("if:")) {
        final listArg = keyAttr.split(":");
        if (listArg[1]=="")
        {
           //la condition est vide 
           return;
        }
        keyAttr = listArg[2];
        if (keyAttr=="v-bind")
        {
          keyAttr="v-bind:"+listArg[3];
        }

        if (keyAttr=="#key")  // cas des tab dynamique
        {
          keyAttr=":key";
        }

      }

      if (attrName.startsWith("[[event")) {
        //print("******************* event > " + keyAttr);
        XUIElementHTML elem = this;
        if (attrName == "[[event@-1]]") {
          elem = firstChildNoText()!;
        }

        elem.propertiesXUI?.forEach((key, value) {
          if (key.startsWith("@")) {
            _doAddEventPhase3(engine, buffer, key, value);
          }
        });
        return;
      }

      final valProp = contentAttr;

      if (keyAttr != "" && contentAttr != null) {
        if (contentAttr is String) {
          final ParseInfo parseInfo = ParseInfo(contentAttr, keyAttr, ParseInfoMode.ATTR);

          String valProp = _processContentPhase3(engine, parseInfo) as String;
          bool mustAdd = true;
          bool isBool = false;
          //-----------------------------------------------------------------------------------
          if (contentAttr != valProp) {
            // si dynamique

            //supprime les balise class et style faussement non vide
            if (keyAttr == "class") {
              valProp = valProp.trim();
            }
            if (keyAttr == "style") {
              valProp = valProp.trim();
              // mieux gerer : decoupe split ';'  et controle 'color:;' ne pas mettre color
              if (valProp == ";" || valProp == ";;") {
                valProp = "";
              }
              final listArg = valProp.split(";");
              final val = StringBuffer();
              for (var i = 0; i < listArg.length; i++) {
                final v = listArg[i].trim();
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

            if (keyAttr=="v-bind:value")
            {
              keyAttr="v-model";
            }

            buffer.html.write(" ");
            buffer.html.write(keyAttr);

            if (!isBool) {
              /// pas d'ajout de valeur si boolean   exemple : dark="true" donne dark
              buffer.html.write("=");
              buffer.html.write('"$valProp"');
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

  void doAddEventPhase2(XUIEngine engine, String key, XUIProperty prop) {
        final xid = this.originElemXUI!.xid;
        final ParseInfo parseInfo = ParseInfo(xid, null, ParseInfoMode.ATTR);
        final String xidCal = this._processContentPhase3(engine, parseInfo) as String;

        engine.bindingManager.addEventMethod(this, XUIBindingEvent(xid : xidCal, eventName: key, name: prop.content.toString()));
  }

  void _doAddEventPhase3(XUIEngine engine, XUIHtmlBuffer buffer, String key, XUIProperty value) {
    buffer.html.write(' $key="\$mth(\'${value.content}\', ...arguments)"');
  }

  void _doChildrenPhase3(XUIEngine engine, XUIHtmlBuffer buffer) {
    children?.forEach((c) {
      (c as XUIElementHTML).processPhase3(engine, buffer);
    });
  }

  bool isXUIIF(cst.XUIEngine engine) {
    final ifContent = propertiesXUI![ATTR_XUI_IF]!.content;
    final ParseInfo parseInfo = ParseInfo(ifContent, null, ParseInfoMode.ATTR);
    final valIf = _processContentPhase3(engine, parseInfo);
    if (valIf == "" || valIf == "false") {
      // xui-if a false
      return false;
    }
    return true;
  }

  bool hasPropXUIIF() {
    return propertiesXUI != null && propertiesXUI!.containsKey(ATTR_XUI_IF);
  }

  bool _hasPropConvertJSON() {
    return propertiesXUI != null && propertiesXUI!.containsKey(ATTR_CONVERT_JSON);
  }

  String getForVar() {
    if (propertiesXUI != null &&
        propertiesXUI!.containsKey(ATTR_XUI_FORVAR)) {
      return propertiesXUI![ATTR_XUI_FORVAR]!.content as String;
    } else {
      return "nb";
    }
  }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class XUIElementHTMLText extends XUIElementHTML {
  StringBuffer? content;

  @override
  void processPhase3(XUIEngine engine, XUIHtmlBuffer buffer) {
    final ParseInfo parseInfo = ParseInfo(content, null, ParseInfoMode.CONTENT);

    if (content == null) {
      return;
    }
    final c = content.toString();
    final cTrim = c.trimRight();
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
        cont = "$cTrim\n";
      }
      // print("result <"+cont+">");
    }
    buffer.html.write(cont);
  }
}

/// provient d'un provider interne
abstract class XUIElementNative extends XUIElementXUI {
  Future doProcessPhase1(XUIEngine engine, XUIElementHTML html) async {
    return null;
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
