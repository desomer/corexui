import 'dart:collection';
//import 'package:yamlicious/yamlicious.dart';
import '../libxui.dart';
import 'XUIActionManager.dart';
import 'XUIConfigManager.dart';
import 'XUIFactory.dart';
import 'XUIJSInterface.dart';
import 'element/XUIElement.dart';
import 'element/XUIParseJSDataBind.dart';
import 'element/XUIProperty.dart';
import 'native/register.dart';
import 'parser/HTMLReader.dart';

const ATTR_XID = "xid";
const ATTR_PARENT_XID =
    "parent-xid"; // utiliser dans <xui-slot xid="[[parent-xid]]-content">

const ATTR_SLOT_NAME = "slot-name";
const ATTR_SLOT_FULL = "slot-full";
const ATTR_XID_SLOT = "xid-slot"; // utiliser dans les data-xid-slot

// ne genere pas de engine.mapInfo et de data-xui-slot
const ATTR_NO_DESIGN = "no-design";
const ATTR_DOC_ID = "doc-id";

// choix du mode pour le design (MODE_FINAL, MODE_DESIGN, etc... )
const ATTR_MODE = "mode";
// n'ajoute pas de noeud dom
const ATTR_NO_DOM = "no-dom";
const ATTR_RELOADER = "reloader";
const ATTR_TRIM_CONTENT = "trim-content";
// mode display des reloader.  par defaut display:content
const ATTR_MODE_DISPLAY = "modedisplay";

const ATTR_CONVERT_JSON = "convert-json";
const ATTR_XUI_IF = "if";

const ATTR_XUI_FORVAR = "forvar";

const ATTR_STYLE_SLOT = "style-slot";
// gestion des tag escape (HTML, HEAD, ETC...) pour le parser dart

const TAG_ESCAPE = "xui-escape-";
const TAG_NO_DOM = "xui-no-dom";
const TAG_RELOADER = "xui-reloader";

const TAG_DOC = "xui-doc";
const TAG_DESIGN = "xui-design";
const TAG_FACTORY = "xui-factory";
const TAG_IMPORT = "xui-import";
const TAG_PROP = "xui-prop";
const TAG_SLOT = "xui-slot";
const TAG_DIV_SLOT =
    "xui-div-slot"; // nom du composant (div) slot dans la class css xui-class-slot

const XUI_COPYZONE_SLOT =
    "xui-copyzone-slot"; // pour la recopie (ctrl c , v , x)
const XUI_TEMPORARY_SLOT = "xui-temporary-slot"; // pour le surround

const MODE_ALL = "";
const MODE_FINAL = "final";
const MODE_DESIGN = "design";
const MODE_TEMPLATE = "template";
const MODE_PREVIEW = "preview";

const SLOT_PREFIX = "_slot-";

///------------------------------------------------------------------
abstract class Provider {
  Future<String> getResourceFutur(String id);
}

class XUIContext {
  String mode;
  String? jsonBinding;
  XUIContext(this.mode, this.jsonBinding);
}

class DicoOrdered<T extends XUIModel> {
  List<T> list = [];
  bool mustSort = true;
  var listByMode = LinkedHashMap<String, List<T>>(); //cache

  add(T elem) {
    mustSort = true;
    list.add(elem);
  }

  List<T> sort(XUIContext ctx) {
    if (mustSort) {
      list.sort();
      listByMode.clear();
    }

    var ret = listByMode[ctx.mode];
    if (ret == null) {
      ret = [];
      listByMode[ctx.mode] = ret;
      for (XUIModel item in list) {
        if (item.mode == MODE_ALL || item.mode!.contains(ctx.mode)) {
          ret.add(item as T);
        }
      }
    }

    return ret;
  }
}

///------------------------------------------------------------------
///  represente un fichier XUI
///      converti les xml en xui (XUIComponent, XUIDesign, XUIModel)
///------------------------------------------------------------------

abstract class XUIReader {
  late Provider provider;
  late var id;

  Future parseFile(XMLElemReader elemReader) async {}
}

abstract class XMLElemReader {
  dynamic parseElem(dynamic parent, XMLElem element) {}
}

class XMLElem {
  late String tag;
  StringBuffer? text;
  LinkedHashMap<dynamic, String>? attributs;
}

/// representation d'un fichier XUI
class XUIResource extends XMLElemReader {
  var components = LinkedHashMap<String, DicoOrdered<XUIComponent>>();
  var designs = LinkedHashMap<String, DicoOrdered<XUIDesign>>();
  var documentation = LinkedHashMap<String, DicoOrdered<XUIModel>>();

  /// les imports
  List<XUIResource> listImport = [];

  XUIReader reader;
  XUIContext context;

  ///------------------------------------------------------------------
  XUIResource(this.reader, this.context);

  void addObjectDesign(var aDesign) {
    var curDesign = designs[aDesign["xid"]];
    if (curDesign == null) {
      var elemXui = XUIElementXUI();
      elemXui.idRessource = reader.id;
      elemXui.xid = aDesign["xid"];
      curDesign = DicoOrdered();
      designs[elemXui.xid!] = curDesign;
      designs[elemXui.xid]!.add(XUIDesign(elemXui, MODE_ALL));
    }
    XUIDesign xuiDesign = curDesign.sort(context).first;

    // print(xuiDesign);

    var props = aDesign["props"];
    if (props != null) {
      for (var aProp in props) {
        // creer la propriete vide
        var variable = aProp["id"];
        var value = aProp["val"];
        var binding = aProp["binding"];

        xuiDesign.elemXUI.propertiesXUI ??= HashMap<String, XUIProperty>();
        // if (xuiDesign.elemXUI.propertiesXUI[variable] == null) {
        xuiDesign.elemXUI.propertiesXUI![variable] = binding == null
            ? XUIProperty(value)
            : XUIPropertyBinding(value, binding);
        // }
        // affecte la prop
        //  xuiDesign.elemXUI.propertiesXUI[variable].content = value;
      }
    }

    List? children = aDesign["children"];
    var parent = xuiDesign.elemXUI;

    if (children != null &&
        (parent.children == null || parent.children!.isEmpty)) {
      // ajout des enfants
      for (var aChild in children) {
        var childElemXui = XUIElementXUI();
        parent.children ??= [];
        childElemXui.xid = aChild["xid"];
        childElemXui.tag = aChild["tag"];
        parent.children?.add(childElemXui);
      }
    }
  }

  Future parseXUIFile() {
    NativeRegister(this);
    return this.reader.parseFile(this);
  }

  //-------------------------------------------------------------------------------------------
  DicoOrdered<XUIComponent>? searchComponent(String tag) {
    var cmp = components[tag];
    if (cmp == null) {
      for (var subFile in listImport) {
        cmp = subFile.searchComponent(tag);
        if (cmp != null) break;
      }
    }
    return cmp;
  }

  List<DicoOrdered<XUIDesign>> searchDesign(List listCmp, String tag) {
    var cmp = designs[tag];
    if (cmp != null) {
      listCmp.add(cmp);
    }
    // if (cmp == null) {
    for (var subFile in listImport) {
      subFile.searchDesign(listCmp, tag);
      //if (cmp != null) break;
    }
    // }
    return listCmp as List<DicoOrdered<XUIDesign>>;
  }

  //-------------------------------------------------------------------------------------------
  void generateDocumentation(XUIEngine engine) {
    documentation.forEach((k, v) {
      XUIElementXUI doc = v.list.first.elemXUI;
      DocInfo docInfo = createDocInfo(doc);
      engine.docInfo[k] = docInfo;
    });

    documentation.clear();

    for (var subFile in listImport) {
      subFile.generateDocumentation(engine);
    }
  }

  DocInfo createDocInfo(XUIElementXUI elem) {
    DocInfo doc;
    doc = DocInfo();

    doc.xid = elem.xid!;
    elem.children?.forEach((prop) {
      if (prop.attributes!["id"] != null) {
        String id = prop.attributes!["id"]?.content;
        if (id == "componentAs") {
          doc.componentAs =
              (prop.children!.first as XUIElementText).content.toString();
        } else if (id == "name") {
          doc.name =
              (prop.children!.first as XUIElementText).content.toString();
        } else if (id == "icon") {
          doc.icon =
              (prop.children!.first as XUIElementText).content.toString();
        } else if (id == "desc") {
          doc.desc =
              (prop.children!.first as XUIElementText).content.toString();
        } else if (id == "add-remove") {
          doc.addRemove =
              (prop.children!.first as XUIElementText).content.toString();
        }
      } else if (prop.attributes!["var"] != null) {
        DocVariables propDoc = DocVariables();
        propDoc.id = prop.attributes!["var"]?.content;
        propDoc.def = prop.attributes!["def"]?.content;
        propDoc.editor = prop.attributes!["editor"]?.content;
        propDoc.link = prop.attributes!["link"]?.content;
        propDoc.list = prop.attributes!["list"]?.content;
        propDoc.cat = prop.attributes!["cat"]?.content;
        propDoc.bindType = prop.attributes!["bind-type"]?.content;

        propDoc.doc =
            (prop.children!.first as XUIElementText).content.toString();
        doc.variables.add(propDoc);
      }
    });

    return doc;
  }

  bool isSupportTextElement(dynamic parent) {
    return (parent as XUIElementXUI).tag.toString().toLowerCase() != TAG_DOC;
  }

  //-------------------------------------------------------------------------------------------
  ///
  ///   Convertie un XML element et XUI element est stocke celui ci en design, component et juste child
  ///
  ///     return l'element pour avoir le parent des enfants
  ///
  @override
  Future<XUIElementXUI?> parseElem(dynamic parent, XMLElem element) async {
    XUIElementXUI? elemXui;

    bool isChild = true;

    if (element.text != null) {
      // cas d'un texte
      if (isSupportTextElement(parent)) {
        elemXui = XUIElementText();
        (elemXui as XUIElementText).content = element.text!;
      } else {
        isChild = false;
      }
    } else {
      //***************   LES IMPORT ***********************************/
      if (element.tag == TAG_IMPORT) {
        var subReader =
            HTMLReader(element.attributs!["xui-path"]!, reader.provider);
        XUIResource subFile = XUIResource(subReader, context);
        await subFile.parseXUIFile();
        // subFile.reader.content = null;
        listImport.add(subFile);
        return Future.value();
      } else if (element.tag == TAG_PROP &&
          (parent as XUIElementXUI).tag.toString().toLowerCase() != TAG_DOC) {
        //***************   LES PROPERTIES EN ATTRIBUT SAUF SI DOCUMENTATION *****************************/
        XUIElementXUI p = parent;
        p.propertiesXUI ??= HashMap<String, XUIProperty>();
        var b = element.attributs!["binding"];
        if (b != null) {
          var prop = XUIPropertyBinding(element.attributs!["val"], b);
          p.propertiesXUI![element.attributs!["id"]!] = prop;
        } else {
          var prop = XUIProperty(element.attributs!["val"]);
          p.propertiesXUI![element.attributs!["id"]!] = prop;
        }

        return Future.value();
      }

      // cas d'un elem HTML
      elemXui = XUIElementXUI();
      elemXui.idRessource = reader.id;

      // gestion des tag escape (HTML, HEAD, ETC...)
      elemXui.tag = element.tag.startsWith(TAG_ESCAPE)
          ? element.tag.substring(TAG_ESCAPE.length)
          : element.tag;

      elemXui.xid = element.attributs![ATTR_XID];
      element.attributs!.remove(ATTR_XID);

      _processAttributs(element, elemXui);

      String mode = MODE_ALL;
      if (elemXui.propertiesXUI != null) {
        var attr = elemXui.propertiesXUI![ATTR_MODE];
        mode = attr == null ? mode : attr.content.toString();
      }

      if (element.tag.toString().toLowerCase() == TAG_DOC) {
        //***************   LES DOCUMENTATION *****************************/
        isChild = false;
        documentation[elemXui.xid!] ??= DicoOrdered();
        documentation[elemXui.xid]!.add(XUIModel(elemXui, mode));
      } else if (element.tag.toString().toLowerCase() == TAG_DESIGN) {
        // gestion des design
        elemXui.tag = null; // pas de tag a affecter si cest le tag design
        if (elemXui.xid != null) {
          isChild = false;
          //  if (elemXui.xid == "xui-script-data") isChild = false;
          designs[elemXui.xid!] ??= DicoOrdered();
          designs[elemXui.xid]!.add(XUIDesign(elemXui, mode));
        }
      } else {
        if (elemXui.xid != null) {
          // ajoute en tant que composant uniquement si parent factory
          if ((parent as XUIElementXUI).tag.toString().toLowerCase() ==
              TAG_FACTORY) {
            isChild = false;
            components[elemXui.xid!] ??= DicoOrdered();
            components[elemXui.xid]!.add(XUIComponent(elemXui, mode));
          }
        }
      }
    }

    if (isChild && parent != null) {
      // ajout des enfants
      (parent as XUIElement).children ??= [];
      parent.children!.add(elemXui!);
    }

    return Future.value(elemXui);
  }

  void _processAttributs(XMLElem element, XUIElementXUI elemXui) {
    element.attributs!.entries.forEach((f) {
      String keyAttr = f.key.toString();
      if (keyAttr.startsWith("-")) {
        keyAttr = keyAttr.substring(1);
      }

      if (keyAttr.startsWith("xui-")) {
        // les xui- sont des properties
        elemXui.propertiesXUI ??= HashMap<String, XUIProperty>();
        elemXui.propertiesXUI![keyAttr.substring(4)] = XUIProperty(f.value);
      } else {
        elemXui.attributes ??= HashMap<String, XUIProperty>();
        elemXui.attributes![keyAttr] =
            XUIProperty(f.value == "" ? null : f.value);
      }
    });
  }
}

///------------------------------------------------------------------

class XUIEngine {
  late XUIResource xuiFile;
  var docInfo = HashMap<String, DocInfo>();

  var mapSlotInfo = HashMap<String, SlotInfo>();
  var bindingInfo = LinkedHashMap<String, XUIBinding>();

  // plus forcement utiliser sauf text avec moustache {{}}
  var dataBindingInfo = XUIParseJSDataBinding();

  Future initialize(HTMLReader reader, XUIContext ctx) async {
    xuiFile = XUIResource(reader, ctx);

    await xuiFile.parseXUIFile();
    xuiFile.generateDocumentation(this);

    //dynamic obj = xuiFile.getObject();

    //final yamld = toYamlString(obj);
    //print("initialize ${reader.id} ok");
    //print(yamld.toString());

    return Future.value();
  }

  ///------------------------------------------------------------------------------------
  /// change une property de design
  XUIProperty? getXUIProperty(String xid, String variable) {
    var listDesign = xuiFile.designs[xid];
    if (listDesign == null) {
      return null;
    }

    var xuiDesign = listDesign.sort(xuiFile.context).first;
    return xuiDesign.elemXUI.propertiesXUI![variable];

    // List<DesignInfo> designs = getDesignInfo(xid, xid, false);
    // for (var design in designs) {
    //   DocInfo doc = design.docInfo;
    //   if (doc != null && doc.variables.isNotEmpty) {
    //     for (var aVariable in doc.variables) {
    //       if (aVariable.id == variable) {
    //         var prop = xuiDesign.elemXUI.propertiesXUI[variable];
    //         if (prop != null) {
    //           return prop;
    //         }
    //       }
    //     }
    //   }
    // }

    // return null;
  }

  SlotInfo? getSlotInfo(String id, String idslot) {
    var info = mapSlotInfo[id];
    if (info == null) info = mapSlotInfo[idslot];

    return info;
  }

  void addXUIDesignEmpty(String xid) {
    XUIElementXUI xuiElem = XUIElementXUI();
    xuiElem.xid = xid;
    xuiElem.idRessource = xuiFile.reader.id;
    xuiFile.designs[xid] ??= DicoOrdered();
    xuiFile.designs[xid]!.add(XUIDesign(xuiElem, MODE_ALL));
  }

  getReloaderID(f) {
    SlotInfo? info = getSlotInfo(f, f);
    if (info == null || !XUIConfigManager.reloaderEnable) {
      return null;
    }
    var html = info.elementHTML;
    var reloaderId;
    while (html != null) {
      if (html.originElemXUI != null &&
          html.originElemXUI!.propertiesXUI != null &&
          html.originElemXUI!.propertiesXUI!.containsKey(ATTR_RELOADER)) {
        reloaderId = html.calculatePropertyXUI(html.originElemXUI!.xid, null);
        html = null;
      } else {
        html = html.parent;
      }
    }
    return reloaderId;
  }

  List<DocInfo> getComponentsFor(String id, String idslot) {
    List<DocInfo> listDoc = [];
    docInfo.forEach((k, doc) {
      if (doc.componentAs != null) {
        listDoc.add(doc);
      }
    });
    return listDoc;
  }

  List<DesignInfo> getDesignInfo(String id, String idslot, bool withParent) {
    List<DesignInfo> listDesignInfo = [];
    SlotInfo? slotInfo = getSlotInfo(id, idslot);
    if (slotInfo == null) {
      XUIConfigManager.printc("getDesignInfo Erreur id inconnu " + id);
      return listDesignInfo;
    }
    DocInfo? doc = docInfo[slotInfo.docId];
    listDesignInfo.add(DesignInfo(slotInfo, doc));
    if (withParent) {
      var next = slotInfo.parentXid;
      while (next != null) {
        slotInfo = getSlotInfo(next, next);
        if (slotInfo!.elementHTML!.tag != TAG_RELOADER) {
          doc = docInfo[slotInfo.docId];
          listDesignInfo.add(DesignInfo(slotInfo, doc));
        }
        next = slotInfo.parentXid;
      }
    }
    return listDesignInfo;
  }

  bool isModeDesign() {
    return xuiFile.context.mode != MODE_FINAL &&
        xuiFile.context.mode != MODE_PREVIEW;
  }

  toHTMLString(XUIHtmlBuffer? writer, String xid, XUIContext ctx) async {
    xuiFile.context = ctx;
    if (writer == null) {
      XUIConfigManager.printc("toHTMLString for only init XUI xid=" + xid);
    } else {
      if (XUIConfigManager.verboseInitXUI) {
        XUIConfigManager.printc("toHTMLString for generate html xid=" + xid);
      }
    }

    var listCmp = xuiFile.searchComponent(xid);
    if (listCmp == null) {
      //dynamic obj = ObjectWriter().toObjects(xuiFile);

      //final yamld = toYamlString(obj);
      //XUIConfigManager.printc("xid inconnu $xid\n" + yamld.toString());

      throw "xid inconnu $xid";
    }

    XUIComponent root = listCmp.sort(ctx).first;

    XUIElementHTML htmlRoot = XUIElementHTML();
    if (isModeDesign() || XUIConfigManager.forceSlotInfo) {
      htmlRoot.attributes ??= HashMap<String, XUIProperty>();
      htmlRoot.attributes!["data-" + ATTR_XID] = XUIProperty(xid);
      htmlRoot.originElemXUI = root.elemXUI;
    }

    if (isModeDesign()) {
      mapSlotInfo.clear(); // vide le slot info contruit dans la Phase2
      bindingInfo.clear();
    }

    await root.processPhase1(this, htmlRoot);
    await root.processPhase2(this, htmlRoot, null);

    if (XUIConfigManager.verboseXUIEngine) {
      XUIConfigManager.printc(
          "-- mapSlotInfo " + mapSlotInfo.length.toString());
      XUIConfigManager.printc("-- docInfo " + docInfo.length.toString());
      XUIConfigManager.printc(
          "-- components " + xuiFile.components.length.toString());
      XUIConfigManager.printc(
          "-- designs " + xuiFile.designs.length.toString());
      XUIConfigManager.printc(
          "-- documentation " + xuiFile.documentation.length.toString());
      XUIConfigManager.printc("-- binding " + bindingInfo.length.toString());
      XUIConfigManager.printc(
          "-- listImport " + xuiFile.listImport.length.toString());
    }

    processPhase2JS();

    if (writer != null) {
      return Future.sync(() => htmlRoot.processPhase3(this, writer));
    }
  }

  List getBindingInfo() {
    var bind = [];
    bindingInfo.forEach((k, v) {
      var des = BindObj();
      des.attr = v.attr;
      des.val = v.value;
      bind.add(des);
    });
    return bind;
  }

  List getSlotTree() {
    TreeSlotBuilder treeSlotBuilder = TreeSlotBuilder();

    // init les childs
    mapSlotInfo.forEach((key, SlotInfo child) {
      child.children = null;
    });

    // reconstruit l'arborescence
    SlotInfo? rootSlot;
    mapSlotInfo.forEach((key, SlotInfo child) {
      var parentID = child.parentXid;
      if (parentID != null) {
        mapSlotInfo[parentID]?.children = mapSlotInfo[parentID]?.children ?? [];
        mapSlotInfo[parentID]?.children!.add(child);
      } else {
        rootSlot = child;
      }
    });

    if (rootSlot != null) {
      treeSlotBuilder.tree
          .add(displaySlot(treeSlotBuilder, rootSlot!, 0, null));
    }

    return treeSlotBuilder.tree;
  }

  TreeSlot displaySlot(TreeSlotBuilder treeSlotBuilder, SlotInfo slot, int tab,
      TreeSlot? parent) {
    var ts = TreeSlot();
    ts.id = treeSlotBuilder.nb++;

    //ts.name = slot.xid+" <"+(slot.slotname??"")+">";
    ts.name = slot.slotname ?? (slot.implement ?? slot.xid!);
    if (slot.docId != null) {
      if (slot.slotname == null && docInfo[slot.docId] != null) {
        ts.name = docInfo[slot.docId]!.name;
      }
    }

    bool isSlot = slot.implement == TAG_SLOT;
    bool isFlow = slot.implement == "xui-flow";
    bool isNoDisplay = isSlot || isFlow;

    if (isSlot || isFlow) {
      ts.name = "#" + ts.name;
    }

    if (XUIConfigManager.verboseTree) {
      String s = "";
      for (var i = 0; i < tab; i++) {
        s = s + "\t";
      }

      s = s + "# " + slot.xid! + " <" + (slot.slotname ?? "") + ">";
      XUIConfigManager.printc(s);
    }

    if (XUIConfigManager.verboseTreeImpl) {
      String s = "";
      for (var i = 0; i < tab; i++) {
        s = s + "\t";
      }

      String? res = slot.idRessource;
      if (res == null) {
        res = "?";
      } else {
        int i = res.lastIndexOf("/");
        int j = res.lastIndexOf(".");
        res = res.substring(i + 1, j);
      }

      s = s +
          "  impl:[" +
          res +
          ":" +
          (slot.implement ?? "no impl") +
          "]\tdoc:<" +
          (slot.docId ?? "") +
          "> ";
      XUIConfigManager.printc(s);

      s = "";
      for (var i = 0; i < tab; i++) {
        s = s + "\t";
      }
      s = s + "  design " + slot.designInfo;
      XUIConfigManager.printc(s);
    }

    for (SlotInfo item in slot.children ?? []) {
      if (!(item.elementHTML!.hasPropXUIIF() &&
          !item.elementHTML!.isXUIIF(this))) {
        var child = displaySlot(treeSlotBuilder, item, tab + 1, ts);

        if (isNoDisplay) {
          if (parent!.children == null) {
            parent.children = [];
          }
          child.name = child.name + " (" + ts.name + ")"; //isFlow  ts
          if (!child.isSlot) {
            parent.children!.add(child);
          } else {
            parent.children!.addAll(child.children ?? []);
          }
        } else {
          if (ts.children == null) {
            ts.children = [];
          }
          if (!child.isSlot) {
            ts.children!.add(child);
          } else {
            ts.children!.addAll(child.children ?? []);
          }
        }
      }
    }
    ts.isSlot = isSlot;

    return ts;
  }

  void processPhase2JS() {
    //var docID = getDocumentationID(elemHtml);
    // DocInfo doc = engine.docInfo[docID];
    // if (doc!=null) {
    //   XUIConfigManager.printc(p.binding +" --------------- bind info " + doc.name);
    // }

    var dicoObjBind = LinkedHashMap<String, List<XUIBinding>>();
    var dicoObjType = LinkedHashMap<String, XUIBinding>();

    StringBuffer buf = NativeInjectText.getcacheText(JS_BINDING)!;

    StringBuffer jsonBinding = StringBuffer();
    this.bindingInfo.forEach((key, bindInfo) {
      String type = "?";

      SlotInfo? slotInfo = getSlotInfo(bindInfo.xid, bindInfo.xid);
      if (slotInfo != null) {
        DocInfo doc = docInfo[slotInfo.docId]!;
        DocVariables varInfo = DocVariables();
        for (DocVariables varCmp in doc.variables) {
          if (varCmp.id == bindInfo.propName) {
            varInfo = varCmp;
            break;
          }
        }

        type = varInfo.bindType != null ? varInfo.bindType! : "?";

        XUIConfigManager.printc("/*/*/*/ xid=" +
            bindInfo.xid +
            " bind on {" +
            bindInfo.attr +
            "} as [" +
            type +
            "] doc on" +
            slotInfo.docId! +
            "#" +
            bindInfo.propName);
      }

      var isBool = false;
      if (bindInfo.value is bool ||
          (bindInfo.value == "true" || bindInfo.value == "false")) {
        isBool = true;
      }
      bindInfo.type = isBool ? "bool" : type;

      var path = "root";

      if (bindInfo.attr.contains(".")) {
        //   gestion de path
        int niv = 0;
        var listAttr = bindInfo.attr.split(".");
        int lastNiv = listAttr.length - 1;
        //var path=".";
        listAttr.forEach((element) {
          var newPath = path + "." + element;
          // XUIConfigManager.printc("--->" + element);
          if (niv != lastNiv) {
            if (dicoObjBind[path] == null) {
              dicoObjBind[path] = [];
            }

            if (newPath.endsWith("[]")) {
              newPath = newPath.substring(0, newPath.length - 2);
            }

            if (dicoObjType[newPath] == null) {
              var newObj = XUIBinding("?", element, "{}", "?");
              newObj.type = "object";
              dicoObjBind[path]?.add(newObj);
              dicoObjType[newPath] = newObj;
              XUIConfigManager.printc(
                  "---> addObj " + element + " on path " + path);
            } else {
              var type = (dicoObjType[newPath]?.type ?? "?");
              XUIConfigManager.printc("---> onObj " +
                  element +
                  " as [" +
                  type +
                  "] on path " +
                  newPath);
            }
          } else {
            // ajout de l'attribut
            var newObj = XUIBinding(
                bindInfo.propName, element, bindInfo.value, bindInfo.xid);
            newObj.type = bindInfo.type;
            if (dicoObjBind[path] == null) {
              dicoObjBind[path] = [];
            }
            dicoObjBind[path]?.add(newObj);
            XUIConfigManager.printc("---> addAttr " + element + " on " + path);
          }

          path = newPath;
          niv++;
        });
      } else {
        // add attribut sur le root '.'
        if (dicoObjBind[path] == null) {
          dicoObjBind[path] = [];
        }

        if (bindInfo.type == "array") {
          dicoObjType[path + "." + bindInfo.attr] = bindInfo;
          XUIConfigManager.printc(
              "---> set array " + bindInfo.attr + " on " + path);
        } else {
          XUIConfigManager.printc(
              "---> set Attr " + bindInfo.attr + " on " + path);
        }
        dicoObjBind[path]?.add(bindInfo);
      }
    });

    processPhase2JSBinding("root", dicoObjBind, jsonBinding);

    XUIProperty? propBinding = getXUIProperty("root", "binding");
    String lastBinding = "";
    if (propBinding != null) {
      lastBinding = propBinding.content.toString();
    }
    String templateBinding = "";
    if (jsonBinding.isNotEmpty) {
      templateBinding = jsonBinding.toString();
    }

    var newBinding = templateBinding;
    if (isModeDesign() || lastBinding != "") {
      newBinding = generateApplicationStateJS(templateBinding, lastBinding);
    }

    if (templateBinding.isNotEmpty) {
      XUIConfigManager.printc("---> ************ TMPL *************** " +
          templateBinding.toString());
      XUIConfigManager.printc(
          "---> ************ NEW  *************** " + newBinding.toString());
      XUIConfigManager.printc(
          "---> ************ LAST *************** " + lastBinding.toString());
    }

    if (newBinding.toString() != lastBinding.toString()) {
      print("************** SAVE STATE APP " + newBinding);
      XUIActionManager(this).changeProperty("root", "binding", newBinding, "");
    }

    var str =
        '\$xui.rootdata = { ...\$xui.rootdata ,' + newBinding + '\n\t\t};';
    buf.clear();
    buf.write(str);
  }

  void processPhase2JSBinding(
      String objName,
      LinkedHashMap<String, List<XUIBinding>> dicoObjBind,
      StringBuffer jsonBinding) {
    dicoObjBind[objName]?.forEach((bindInfo) {
      var type = bindInfo.type;

      var v = type == "bool" ? bindInfo.value : '"' + bindInfo.value + '"';

      if (type == "array") {
        var newjsonBinding = StringBuffer();
        processPhase2JSBinding(
            objName + "." + bindInfo.attr, dicoObjBind, newjsonBinding);
        v = "[{ " + newjsonBinding.toString() + " }]";
      }

      if (v == null && type == "bool") {
        v = 'false';
      }

      if (type == "object") {
        var newjsonBinding = StringBuffer();
        processPhase2JSBinding(
            objName + "." + bindInfo.attr, dicoObjBind, newjsonBinding);
        v = "{ " + newjsonBinding.toString() + " }";
      }

      if (type != "item-array") {
        if (jsonBinding.isNotEmpty) {
          jsonBinding.write(',');
        }
        jsonBinding.write('"' + bindInfo.attr + '": ' + v.toString());
      }
    });
  }
}

///------------------------------------------------------------------
class SlotInfo {
  String? xid;
  String? parentXid;
  String? slotname;
  String? docId;
  String? idRessource;
  String? implement;
  late String designInfo;
  // chaine caractere des info de design (NB + nom des fichier)
  XUIElementHTML? elementHTML;
  List<SlotInfo>? children;
}

class TreeSlotBuilder {
  List<TreeSlot> tree = [];
  int nb = 0;
}

class DocInfo {
  late String xid;
  String? componentAs;
  late String name;
  late String icon;
  late String desc;
  String? addRemove;
  List<DocVariables> variables = [];
}

class DocVariables {
  late String id;
  String? def; // valeur par defaut
  String? editor;
  String? doc; // description
  String? link; // lien vers la doc
  String? list; // pour les combox
  String? cat; // la categorie  layout/style
  String? bindType;
}

///------------------------------------------------------------------
class DesignInfo {
  SlotInfo slotInfo;
  DocInfo? docInfo;

  DesignInfo(this.slotInfo, this.docInfo);
}
