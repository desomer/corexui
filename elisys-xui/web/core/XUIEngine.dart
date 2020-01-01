library XUIConstants;

import 'dart:collection';

import 'XUIFactory.dart';
import 'element/XUIElement.dart';
import 'element/XUIProperty.dart';
import 'native/register.dart';
import 'parser/HTMLReader.dart';

const ATTR_XID = "xid";
const ATTR_SLOT_NAME = "slot-name";
const ATTR_SLOT_FULL = "slot-full";
const ATTR_XID_SLOT = "xid-slot";
const ATTR_MODE = "mode";

const TAG_ESCAPE = "xui-escape-";
const TAG_NO_DOM = "xui-no-dom";

const TAG_DOC = "xui-doc";
const TAG_DESIGN = "xui-design";
const TAG_FACTORY = "xui-factory";
const TAG_IMPORT = "xui-import";
const TAG_DIV_SLOT = "xui-div-slot";
const TAG_PROP = "xui-prop";

const MODE_ALL = "";
const MODE_FINAL = "final";
const MODE_TEMPLATE = "template";
const MODE_DESIGN = "design";

/*************************************************************************** */
abstract class Provider {
  Future<String> getResourceFutur(String id);
}

class XUIContext {
  String mode;
  XUIContext(this.mode);
}

class DicoOrdered<T extends XUIModel> {
  List<T> list = [];
  bool mustSort = true;
  var listByMode = LinkedHashMap<String, List<T>>();

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
        if (item.mode == MODE_ALL || item.mode.contains(ctx.mode)) {
          ret.add(item);
        }
      }
    }

    return ret;
  }
}

/***************************************************************************************/
/* converti les xml en xui 
*
****************************************************************************************/

class XUIResource extends XMLElemReader {
  var components = LinkedHashMap<String, DicoOrdered<XUIComponent>>();
  var designs = LinkedHashMap<String, DicoOrdered<XUIDesign>>();
  var documentation = LinkedHashMap<String, DicoOrdered<XUIModel>>();

  HTMLReader reader;
  List<XUIResource> listSubXUIResource = [];
  XUIContext context;

  /**************************************************************/
  XUIResource(this.reader, this.context);

  Future parse() {
    NativeRegister(this);
    return this.reader.parseElem(this);
  }

  DicoOrdered<XUIComponent> searchComponent(String tag) {
    var cmp = components[tag];
    if (cmp == null) {
      for (var subFile in listSubXUIResource) {
        cmp = subFile.searchComponent(tag);
        if (cmp != null) break;
      }
    }
    return cmp;
  }

  DicoOrdered<XUIDesign> searchDesign(String tag) {
    var cmp = designs[tag];
    if (cmp == null) {
      for (var subFile in listSubXUIResource) {
        cmp = subFile.searchDesign(tag);
        if (cmp != null) break;
      }
    }
    return cmp;
  }

  void generateDocumentation(XUIEngine engine) {
    documentation.forEach((k, v) {
      XUIElementXUI doc = v.list.first.elemXUI;
      DocInfo docInfo = getDocInfo(doc);
      engine.docInfo[k] = docInfo;
    });

    documentation.clear();

    for (var subFile in listSubXUIResource) {
      subFile.generateDocumentation(engine);
    }
  }

  DocInfo getDocInfo(XUIElementXUI elem) {
    DocInfo doc = null;
    doc = DocInfo();

    doc.xid = elem.xid;
    elem.children?.forEach((prop) {
      if (prop.attributes["id"] != null) {
        String id = prop.attributes["id"]?.content;
        if (id == "componentAs") {
          doc.componentAs = (prop.children.first as XUIElementText).content;
        } else if (id == "name") {
          doc.name = (prop.children.first as XUIElementText).content;
        } else if (id == "icon") {
          doc.icon = (prop.children.first as XUIElementText).content;
        } else if (id == "desc") {
          doc.desc = (prop.children.first as XUIElementText).content;
        }
      } else if (prop.attributes["var"] != null) {
        DocVariables propDoc = DocVariables();
        propDoc.id = prop.attributes["var"]?.content;
        propDoc.def = prop.attributes["def"]?.content;
        propDoc.editor = prop.attributes["editor"]?.content;
        propDoc.doc = (prop.children.first as XUIElementText).content;
        doc.variables.add(propDoc);
      }
    });

    return doc;
  }

  bool isSupportTextElement(dynamic parent) {
    return (parent as XUIElementXUI).tag.toString().toLowerCase() != TAG_DOC;
  }

/**
 *   Convertie un XML element et XUI element est stocke celui ci en design, component et juste child
 * 
 *     return l'element pour avoir le parent des enfants 
 */
  @override
  Future<XUIElementXUI> parseElem(dynamic parent, XMLElem element) async {
    XUIElementXUI elemXui;

    bool isChild = true;

    if (element.text != null) {
      // cas d'un texte
      if (isSupportTextElement(parent)) {
        elemXui = XUIElementText();
        (elemXui as XUIElementText).content = element.text;
      } else
        isChild = false;
    } else {
      //***************   LES IMPORT ***********************************/
      if (element.tag == TAG_IMPORT) {
        var subReader =
            HTMLReader(element.attributs["xui-path"], reader.provider);
        XUIResource subFile = XUIResource(subReader, context);
        await subFile.parse();
        subFile.reader.content = null;
        listSubXUIResource.add(subFile);
        return Future.value(null);
      } else if (element.tag == TAG_PROP &&
          (parent as XUIElementXUI).tag.toString().toLowerCase() != TAG_DOC) {
        //***************   LES PROPERTIES EN ATTRIBUT SAUF SI DOCUMENTATION *****************************/
        XUIElementXUI p = parent;
        p.propertiesXUI ??= HashMap<String, XUIProperty>();
        p.propertiesXUI[element.attributs["id"]] =
            XUIProperty(element.attributs["val"]);
        return Future.value(null);
      }

      // cas d'un elem
      elemXui = XUIElementXUI();

      elemXui.idRessource = reader?.id;

      // gestion des tag escape (HTML, HEAD, ETC...)
      elemXui.tag = element.tag.startsWith(TAG_ESCAPE)
          ? element.tag.substring(TAG_ESCAPE.length)
          : element.tag;

      elemXui.xid = element.attributs[ATTR_XID];
      element.attributs.remove(ATTR_XID);

      processAttributs(element, elemXui);

      String mode = MODE_ALL;
      if (elemXui.propertiesXUI != null) {
        var attr = elemXui.propertiesXUI[ATTR_MODE];
        mode = attr == null ? mode : attr.content.toString();
      }

      if (element.tag.toString().toLowerCase() == TAG_DOC) {
        isChild = false;
        documentation[elemXui.xid] ??= DicoOrdered();
        documentation[elemXui.xid].add(XUIModel(elemXui, mode));
      } else if (element.tag.toString().toLowerCase() == TAG_DESIGN) {
        // gestion des design
        elemXui.tag = null; // pas de tag a affecter si cest le tag design
        if (elemXui.xid != null) {
          isChild = false;
          designs[elemXui.xid] ??= DicoOrdered();
          designs[elemXui.xid].add(XUIDesign(elemXui, mode));
        }
      } else {
        if (elemXui.xid != null) {
          // ajoute en tant que composant uniquement si parent factory
          if ((parent as XUIElementXUI).tag.toString().toLowerCase() ==
              TAG_FACTORY) {
            isChild = false;
            components[elemXui.xid] ??= DicoOrdered();
            components[elemXui.xid].add(XUIComponent(elemXui, mode));
          }
        }
      }
    }

    if (isChild) {
      // ajout des enfants
      (parent as XUIElement)?.children ??= [];
      (parent as XUIElement)?.children?.add(elemXui);
    }

    return Future.value(elemXui);
  }

  void processAttributs(XMLElem element, XUIElementXUI elemXui) {
    element.attributs.entries.forEach((f) {
      if (f.key.toString().startsWith("xui-")) {
        // les xui- sont des properties
        elemXui.propertiesXUI ??= HashMap<String, XUIProperty>();
        elemXui.propertiesXUI[f.key.toString().substring(4)] =
            XUIProperty(f.value);
      } else {
        elemXui.attributes ??= HashMap<String, XUIProperty>();
        elemXui.attributes[f.key] = XUIProperty(f.value == "" ? null : f.value);
      }
    });
  }
}

/************************************************************************************** */

class XUIEngine {
  XUIResource xuiFile;
  var mapInfo = HashMap<String, SlotInfo>();
  var docInfo = HashMap<String, DocInfo>();

  Future initialize(HTMLReader reader, XUIContext ctx) async {
    xuiFile = XUIResource(reader, ctx);

    await xuiFile.parse();
    xuiFile.generateDocumentation(this);
    return Future.value();
  }

  SlotInfo getSlotInfo(String id, String idslot) {
    var info = mapInfo[id];
    if (info == null) info = mapInfo[idslot];

    return info;
  }

  List<DesignInfo> getDesignInfo(String id, String idslot)
  {
    List<DesignInfo> listDesignInfo=[];
    SlotInfo slotInfo = getSlotInfo(id, idslot);
    if (slotInfo==null)
    {
        print("Erreur id inconnu " + id);
        return listDesignInfo;
    }
    DocInfo doc = docInfo[slotInfo.docId];
    listDesignInfo.add(DesignInfo(slotInfo, doc));
    var next = slotInfo.parentXid;
    while(next!=null)
    {
      slotInfo = getSlotInfo(next, next);
      doc = docInfo[slotInfo.docId];
      listDesignInfo.add(DesignInfo(slotInfo, doc));
      next = slotInfo.parentXid;
    }
    return listDesignInfo;
  }

  toHTMLString(XUIHtmlBuffer writer, String xid, XUIContext ctx) async {
    xuiFile.context = ctx;
    XUIComponent root = xuiFile.searchComponent(xid).sort(ctx).first;

    XUIElementHTML htmlRoot = XUIElementHTML();
    if (ctx.mode != MODE_FINAL) {
      htmlRoot.attributes ??= HashMap<String, XUIProperty>();
      htmlRoot.attributes["data-"+ATTR_XID] = XUIProperty(xid);
      htmlRoot.origin = root.elemXUI;
    }

    mapInfo.clear();
    await root.processPhase1(this, htmlRoot);
    await root.processPhase2(this, htmlRoot, null);
    print("-----------------------------------------------");

    return Future.sync(() => htmlRoot.toHTMLString(writer));
  }

  void addDesign(String xid, String html) async {
    XUIResource res = XUIResource(null, xuiFile.context);

    dynamic ret = await xuiFile.reader.parseString(html, res);

    if (xid != null)
      xuiFile.designs[xid] ??= DicoOrdered()..add(XUIDesign(ret, MODE_ALL));
  }
}

/************************************************************************************** */
class SlotInfo {
  String xid;
  String parentXid;
  String slotname;
  String docId;
  String idRessource;
  XUIElementHTML elementHTML;
}

class DocInfo {
  String xid;
  String componentAs;
  String name;
  String icon;
  String desc;
  List<DocVariables> variables = [];
}

class DocVariables {
  String id;
  String def;
  String editor;
  String doc;
}

/**************************************************************** */
class DesignInfo {
  SlotInfo slotInfo;
  DocInfo docInfo;

  DesignInfo(this.slotInfo, this.docInfo);
}
