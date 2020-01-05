import 'dart:collection';

import 'XUIEngine.dart';
import 'XUIFactory.dart';
import 'element/XUIElement.dart';
import 'element/XUIProperty.dart';

class XUIActionManager {
  XUIEngine engine;

  XUIActionManager(this.engine);

  Future<XUIElementXUI> addDesign(String xid, String html) async {
    XUIResource res = XUIResource(null, engine.xuiFile.context);

    XUIElementXUI xuidesign =
        await engine.xuiFile.reader.parseString(html, res);

    if (xid != null) {
      engine.xuiFile.designs[xid] ??= DicoOrdered()
        ..add(XUIDesign(xuidesign, MODE_ALL));
    }

    if (xuidesign.children != null) {
      XUIElementXUI xuiCmp = xuidesign.children.first;
      DocInfo doc = engine.docInfo[xuiCmp.tag];
      if (doc != null && doc.variables.isNotEmpty) {
        for (var variable in doc.variables) {
          if (variable.def != null) {
            xuiCmp.propertiesXUI ??= HashMap<String, XUIProperty>();
            xuiCmp.propertiesXUI[variable.id] = XUIProperty(variable.def);
          }
        }
      }
    }

    return Future.value(xuidesign);
  }

  /// gestion du remove
  UndoAction removeDesign(String xid, String mode, [bool withChild=true]) {
    SlotInfo info = engine.getSlotInfo(xid, xid);
    if (info == null) {
      throw "xid inconnu $xid";
    }
    var addIn = info.elementHTML?.parent?.designBy;
    if (addIn != null) {
      for (var design in addIn) {
        if (mode == null || design.mode == mode) {
          var xidParent = design.elemXUI.xid;
          bool hasText = false;
          int nbChildNoText = 0;
          int idx = 0;
          int idxToDelete = -1;
          for (var child in design.elemXUI.children) {
            if (child is XUIElementText && !hasText) {
              hasText = child.content.trim().isNotEmpty;
            } else if (child is XUIElementXUI) {
              nbChildNoText++;
              if (child.xid == xid) {
                idxToDelete = idx;
              }
            }
            idx++;
          }
          if (nbChildNoText == 1 && idxToDelete >= 0 && !hasText) {
            design.elemXUI.children = null;
            print("remove all <$xid> on parent <$xidParent>");
          } else if (nbChildNoText >= 0) {
            design.elemXUI.children.removeAt(nbChildNoText);
            print("remove only <$xid> on parent <$xidParent>");
          }

          if (design.elemXUI.isEmpty()) {
            print("delete design parent <$xidParent>");
            engine.xuiFile.designs.remove(xidParent);
          }
          
          print("delete design <$xid>");
          engine.xuiFile.designs.remove(xid);
        }
      }

      // supprime les enfants
      if (withChild) {
        _removeChild(info.elementHTML, mode);
      }
    }
    return UndoAction();
  }

  void _removeChild(XUIElementHTML elem, String mode) {
    if (elem.children != null) {
      for (var childHtml in elem.children) {
          if (childHtml is XUIElementHTML)
          {
            if (childHtml.designBy!=null)
            {
                for (var design in childHtml.designBy) {
                     if (mode == null || design.mode == mode) {
                        // remode all children
                        if (design.elemXUI.children!=null) {
                          for (var childDesign in design.elemXUI.children) {
                              if (childDesign is XUIElementXUI  && childDesign.xid!=null)
                              {
                                  removeDesign(childDesign.xid, mode, false);
                              }
                          }
                        }

                       // removeDesign(design.elemXUI.xid, mode, false);
                     }
                }
            }
            _removeChild(childHtml, mode);
          }
      }
    }
  }
}

class UndoAction {}
