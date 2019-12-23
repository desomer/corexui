library XUIConstants;

import 'dart:collection';

import 'XUIFactory.dart';
import 'element/XUIElement.dart';
import 'element/XUIProperty.dart';
import 'native/register.dart';
import 'parser/HTMLReader.dart';

const ATTR_XID = "xid";
const ATTR_SLOT_NAME = "slot-name";

const TAG_ESCAPE = "xui-escape-";
const TAG_NO_DOM = "xui-no-dom";

const TAG_DESIGN = "xui-design";
const TAG_FACTORY = "xui-factory";
const TAG_IMPORT = "xui-import";
const TAG_PROP = "xui-prop";

/*************************************************************************** */
abstract class Provider {
  Future<String> getResourceFutur(String id);
}

class DicoOrdered<T> {
  List<T> list = [];
  bool mustSort = true;

  add(T elem) {
    mustSort = true;
    list.add(elem);
  }

  List<T> sort() {
    if (mustSort) list.sort();
    return list;
  }
}

/***************************************************************************************/
/* converti les xml en xui 
*
****************************************************************************************/
class XUIResource extends XMLElemReader {
  var components = LinkedHashMap<String, DicoOrdered<XUIComponent>>();
  var designs = LinkedHashMap<String, DicoOrdered<XUIDesign>>();
  HTMLReader reader;
  List<XUIResource> listSubXUIResource = [];

  XUIResource(HTMLReader reader) {
    this.reader = reader;
  }

  Future parse() {
    NativeRegister(this);
    return this.reader.parseElem(this);
  }

  DicoOrdered<XUIComponent> searchComponent(String tag) {
    var cmp = components[tag];
    if (cmp==null)
    {
        for (var subFile in listSubXUIResource) {
            cmp = subFile.searchComponent(tag);
            if (cmp!=null) break;
        }
    }
    return cmp;
  }

    DicoOrdered<XUIDesign> searchDesign(String tag) {
    var cmp = designs[tag];
    if (cmp==null)
    {
        for (var subFile in listSubXUIResource) {
            cmp = subFile.searchDesign(tag);
            if (cmp!=null) break;
        }
    }
    return cmp;
  }

/**
 *   Convertie un XML element et XUI element est stocke celui ci en design, component et juste child
 * 
 *     return l'element pour avoir le parent des enfants 
 */
  @override
  Future<XUIElementXUI> parseElem(dynamic parent, XMLElem element) async {
    XUIElementXUI elemXui;

    if (element.text != null) {
      // cas d'un texte
      elemXui = XUIElementText();
      (elemXui as XUIElementText).content = element.text;
    } else {
      if (element.tag==TAG_IMPORT)
      {
        var subReader = HTMLReader(element.attributs["xui-path"], reader.provider);
        XUIResource subFile =XUIResource(subReader);
        await subFile.parse();
        subFile.reader.content=null;
        listSubXUIResource.add(subFile);
        return Future.value(null);
      }
      else if (element.tag==TAG_PROP)
      {
        XUIElementXUI p = parent;
        p.propertiesXUI ??= HashMap<String, XUIProperty>();
        p.propertiesXUI[element.attributs["id"]] = XUIProperty(element.attributs["val"]);
        return Future.value(null);
      }

      // cas d'un elem
      elemXui = XUIElementXUI();

      elemXui.tag = element.tag.startsWith(TAG_ESCAPE)
          ? element.tag.substring(TAG_ESCAPE.length)
          : element.tag;
      elemXui.xid = element.attributs[ATTR_XID];
      element.attributs.remove(ATTR_XID);

      element.attributs.entries.forEach((f) {
        if (f.key.toString().startsWith("xui-")) {
          elemXui.propertiesXUI ??= HashMap<String, XUIProperty>();
          elemXui.propertiesXUI[f.key.toString().substring(4)] = XUIProperty(f.value);
        } else {
          elemXui.attributes ??= HashMap<String, XUIProperty>();
          elemXui.attributes[f.key] =
              XUIProperty(f.value == "" ? null : f.value);
        }
      });

      if (element.tag.toString().toLowerCase() == TAG_DESIGN) {
        // gestion des design
        elemXui.tag = null; // pas de tag a affecter si cest le tag design
        if (elemXui.xid!=null)
        {
            designs[elemXui.xid] ??= DicoOrdered();
            designs[elemXui.xid].add(XUIDesign(elemXui));
        }

      } else {
        if (elemXui.xid != null) {
          // gestion des xui
          var elemParent = parent as XUIElementXUI;
          // ajoute en tant que composant uniquement si parent factory
          if (elemParent.tag.toString().toLowerCase() == TAG_FACTORY) {
               components[elemXui.xid] ??= DicoOrdered();
               components[elemXui.xid].add(XUIComponent(elemXui));
          }
        }
      }
    }

    (parent as XUIElement)?.children ??= [];
    (parent as XUIElement)?.children?.add(elemXui);

    return Future.value(elemXui);
  }
}

/************************************************************************************** */

class XUIEngine {
  Future start(HTMLReader reader, XUIHtmlBuffer writer, String xid) async {
    var xuiFile = XUIResource(reader);

    await xuiFile.parse();

    XUIComponent root = xuiFile.searchComponent(xid).list.first;

    XUIElementHTML htmlRoot = XUIElementHTML();

    await root.processPhase1(xuiFile, htmlRoot);
    root.processPhase2(xuiFile, htmlRoot);

    return Future.sync(()=>htmlRoot.toHTMLString(writer));


  }
}
