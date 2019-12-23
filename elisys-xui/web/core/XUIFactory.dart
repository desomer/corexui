import 'dart:collection';

import 'XUIEngine.dart' as Const;
import 'XUIEngine.dart';
import 'element/XUIElement.dart';
import 'element/XUIProperty.dart';

/************************************************************* */
class XUIHtmlBuffer {
  var html = StringBuffer();
  int idxTab = 0;

  addTab() {
    for (var i = 0; i < idxTab; i++) {
      html.write("   ");
    }
  }

  tab(int i) {
    idxTab += i;
  }
}
/************************************************************* */
class XUIComponent extends XUIModel {
  XUIComponent(e) : super(e);
}

class XUIDesign extends XUIModel {
  XUIDesign(e) : super(e);
}

/************************************************************** */
class XUIModel implements Comparable<XUIModel> {
  int priority = 0; // gestion de la priorité d'application
  XUIElementXUI elem;

  XUIModel(e) {
    this.elem = e;
  }

  Future processPhase1(XUIResource xuifile, XUIElementHTML elemHtml) async {
    var tag = elem.tag;

    /********** AFFECTE LES INFO POUR LE DESIGNER *************/
    if (this is XUIComponent)
      elemHtml.implementBy ??= []..add(this);
    else if (this is XUIDesign) elemHtml.designBy ??= []..add(this);

    /*********** EXECUTE LES NATIVES ********/
    if (elem is XUIElementNative) {
      XUIModel model =
          await (elem as XUIElementNative).doProcessPhase1(xuifile, elemHtml);

      await model.processPhase1(xuifile, elemHtml);
      return Future.value();
    }
    /*****************************************************************/

    if (tag != null) elemHtml.tag = tag;

    // properties
    processAttributes(elemHtml);

    // properties
    processProperties(elemHtml);

    // lance les children
    await processChildren(elemHtml, xuifile);

    // lance les design (pour affectation property utilise)
    if (elem.xid != null && this is! XUIDesign) {
      var dico = xuifile.searchDesign(elem.xid);

      if (elem.xid=="inject-after-body")
          elem=elem;

      if (dico != null) {
        for (var item in dico.sort()) {
          await item.processPhase1(xuifile, elemHtml);
        }
      }
    }

    // lance implementation xui si affecter par le design (ex: remplace un slot par un div)
    if (elem.tag != null  /*&& (elem.tag != tag || this is! XUIComponent)*/) {
      DicoOrdered<XUIComponent> cmp = xuifile.searchComponent(elem.tag);

      if (cmp != null) {
        for (var item in cmp.sort()) {
          await item.processPhase1(xuifile, elemHtml);
        }
      }
    }

    if (elem.xid != null) {
      elemHtml.attributes ??= HashMap<String, XUIProperty>();
      elemHtml.attributes["data-xid"] = XUIProperty(elem.xid);
    }

    return Future.value();
  }



  Future processChildren(XUIElementHTML elemHtml, XUIResource xuifile) async {
    if (elem.children != null) {
      for (var item in elem.children) {
        await doChild(item, elemHtml, xuifile);
      }
    }
    return Future.value();
  }

  Future doChild(c, XUIElementHTML elemHtml, xuifile) async {
    if (c is XUIElementXUI) {
      var childHtml;

      if (c is XUIElementText) {
        childHtml = XUIElementHTMLText();
        childHtml.content = c.content;
        childHtml.parent = elemHtml;
        childHtml.origin = c;
        
      } else {
        childHtml = XUIElementHTML();
        childHtml.parent = elemHtml;
        childHtml.origin = c;

        var model = XUIModel(c);
        await model.processPhase1(xuifile, childHtml);
      }

      elemHtml.children ??= [];

      return Future.sync(() => elemHtml.children.add(childHtml));
    }
  }

  void processAttributes(XUIElementHTML elemHtml) {
    if (elem.attributes != null) {
      elemHtml.attributes ??= HashMap<String, XUIProperty>();
      elem.attributes.entries.forEach((f) {
        String v = f.value.content;

        if (f.key.toLowerCase() == "style") {
          XUIProperty style = elemHtml.attributes[f.key];
          completeAttribut(style, elemHtml, f, v, ";");
        } else if (f.key.toLowerCase() == "class") {
          XUIProperty classe = elemHtml.attributes[f.key];
          completeAttribut(classe, elemHtml, f, v, " ");
        } else
          elemHtml.attributes[f.key] = XUIProperty(v);
      });
    }
  }

  void processProperties(XUIElementHTML elemHtml) {
    if (elem.propertiesXUI != null) {
      elem.propertiesXUI.entries.forEach((prop) {

        if (elemHtml.propertiesXUI==null)
            elemHtml.propertiesXUI=HashMap<String, XUIProperty>();

        String v = prop.value.content;
        elemHtml.propertiesXUI[prop.key]= prop.value;

        if (prop.key.toLowerCase() == Const.ATTR_SLOT_NAME) {
          elemHtml.attributes ??= HashMap<String, XUIProperty>();
          elemHtml.attributes["data-slot"] = XUIProperty(v);
        }
      });
    }
  }

  void completeAttribut(XUIProperty style, XUIElementHTML elemHtml,
      MapEntry<String, XUIProperty> f, String v, String sep) {
    if (style == null)
      elemHtml.attributes[f.key] = XUIProperty(v);
    else {
      elemHtml.attributes[f.key].content += sep + v;
    }
  }

  void processPhase2(XUIResource xuifile, XUIElementHTML elemHtml) {
    elemHtml.implementBy?.forEach((cmp) {
      if (cmp.elem is XUIElementNative) {
        (cmp.elem as XUIElementNative).doProcessPhase2(xuifile, elemHtml);
      }
    });

    elemHtml.children?.forEach((child) {
      processPhase2(xuifile, child);
    });
  }

  @override
  int compareTo(XUIModel other) {
    return priority.compareTo(other.priority);
  }
}
