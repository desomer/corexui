import 'dart:collection';
//import 'package:yamlicious/yamlicious.dart';
import 'XUIBindingManager.dart';
import 'XUIConfigManager.dart';
import 'XUIFactory.dart';
import 'XUIJSInterface.dart';
import 'element/XUIElement.dart';
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

const ATTR_XUI_FORVAR = "for-nbvar";

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
const TAG_DIV_SLOT = "xui-div-slot"; // nom du composant (div) slot dans la class css xui-class-slot

const XUI_COPYZONE_SLOT = "xui-copyzone-slot"; // pour la recopie (ctrl c , v , x)
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
  String? cause;
  XUIContext(this.mode);

  void setCause(String cause) {
    this.cause = cause;
  }
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
  late XUIBindingManager bindingManager= XUIBindingManager(this);


  // plus forcement utiliser sauf text avec moustache {{}}
  //var dataBindingInfo = XUIParseJSDataBinding();

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
      bindingManager.bindingInfo.clear();
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
      XUIConfigManager.printc("-- binding " + bindingManager.bindingInfo.length.toString());
      XUIConfigManager.printc(
          "-- listImport " + xuiFile.listImport.length.toString());
    }

    if (ctx.cause != "getHtmlFromXUI" && ctx.cause != "getJSDesignInfo") {
      bindingManager.processPhase2JS(ctx);
    }

    if (writer != null) {
      return Future.sync(() => htmlRoot.processPhase3(this, writer));
    }
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
      treeSlotBuilder.tree.add(displaySlot(treeSlotBuilder, rootSlot!, 0, null));
    }

    return treeSlotBuilder.tree;
  }

  TreeSlot displaySlot(TreeSlotBuilder treeSlotBuilder, SlotInfo slotInfo, int tab,
      TreeSlot? parent) {
    var aTreeSlot = TreeSlot();

    treeSlotBuilder.nb++;
    aTreeSlot.id = slotInfo.xid??treeSlotBuilder.nb.toString(); 

    //ts.name = slot.xid+" <"+(slot.slotname??"")+">";
    aTreeSlot.name = slotInfo.slotname ?? (slotInfo.implement ?? slotInfo.xid!);
    aTreeSlot.icon ="mdi-web";

    if (slotInfo.docId != null) {
      if (slotInfo.slotname == null && docInfo[slotInfo.docId] != null) {
        aTreeSlot.name = docInfo[slotInfo.docId]!.name ?? "no slot name";  // affecte le nom du composant si pas de slotName
        aTreeSlot.icon= docInfo[slotInfo.docId]!.icon ?? "mdi-web";
      }
      else
      {
        aTreeSlot.icon= (docInfo[slotInfo.docId]?.icon) ?? "mdi-web";
      }
    }

    bool isSlot = slotInfo.implement == TAG_SLOT;
    bool isFlow = slotInfo.implement == "xui-flow";
    bool isNoDisplay = isSlot || isFlow;

    var pathTo = slotInfo.elementHTML?.propertiesXUI?["topath"];
    if (pathTo!=null)
    {
      var ret = slotInfo.elementHTML!.calculatePropertyXUI(pathTo.content,  null);
      aTreeSlot.toPath=ret.toString();
      isNoDisplay=false;
      isSlot=false;
    }


    if (isSlot || isFlow) {
      aTreeSlot.name = "#" + aTreeSlot.name;
    }

    //------------------------------------------------
    if (XUIConfigManager.verboseTree) {
      String s = "";
      for (var i = 0; i < tab; i++) {
        s = s + "\t";
      }

      s = s + "# " + slotInfo.xid! + " <" + (slotInfo.slotname ?? "") + ">  " + (aTreeSlot.toPath);
      XUIConfigManager.printc(s);
    }

    if (XUIConfigManager.verboseTreeImpl) {
      String s = "";
      for (var i = 0; i < tab; i++) {
        s = s + "\t";
      }

      String? res = slotInfo.idRessource;
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
          (slotInfo.implement ?? "no impl") +
          "]\tdoc:<" +
          (slotInfo.docId ?? "") +
          "> ";
      XUIConfigManager.printc(s);

      s = "";
      for (var i = 0; i < tab; i++) {
        s = s + "\t";
      }
      s = s + "  design " + slotInfo.designInfo;
      XUIConfigManager.printc(s);
    }
    //------------------------------------------------

    for (SlotInfo item in slotInfo.children ?? []) {
      if (!(item.elementHTML!.hasPropXUIIF() &&
          !item.elementHTML!.isXUIIF(this)) && slotInfo.xid != XUI_COPYZONE_SLOT) {

        var child = displaySlot(treeSlotBuilder, item, tab + 1, aTreeSlot);

        if (isNoDisplay) { // n'affiche pas les slot
          if (parent!.children == null) {
            parent.children = [];
          }
          child.name = child.name + " (" + aTreeSlot.name + ")";    //affecte le nom du slot au enfant
          if (!child.isSlot) {
            parent.children!.add(child);
            child.parent=parent;
          } else {
            parent.children!.addAll(child.children ?? []);
            parent.children!.forEach((element) { (element as TreeSlot).parent = parent; });
          }
        } else {
          if (aTreeSlot.children == null) {
            aTreeSlot.children = [];
          }
          if (!child.isSlot) {
            aTreeSlot.children!.add(child);
            child.parent=aTreeSlot;
          } else {
            aTreeSlot.children!.addAll(child.children ?? []);
            aTreeSlot.children!.forEach((element) { (element as TreeSlot).parent = aTreeSlot; });
          }
        }
      }
    }
    aTreeSlot.isSlot = isSlot;

    return aTreeSlot;
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
  String? name;
  String? icon;
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
