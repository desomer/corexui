import 'dart:collection';

import 'XUIEngine.dart';
import 'XUIFactory.dart';
import 'element/XUIElement.dart';
import 'element/XUIProperty.dart';

class XUIActionManager {
  XUIEngine engine;

  XUIActionManager(this.engine);

  /// ajoute un nouveau composant  (html)
  ///     affecte les valeurs par defaut
  Future<XUIElementXUI> addDesign(String xid, String html) async {
    XUIResource res = XUIResource(null, engine.xuiFile.context);

    XUIElementXUI xuidesign =
        await engine.xuiFile.reader.parseString(html, res);

    if (xid != null) {
      xuidesign.xid = xid;
      engine.xuiFile.designs[xid] ??= DicoOrdered();
      engine.xuiFile.designs[xid].add(XUIDesign(xuidesign, MODE_ALL));
    }

    if (xuidesign.children != null) {
      XUIElementXUI xuiCmp = xuidesign.children.first;
      DocInfo doc = engine.docInfo[xuiCmp.tag];
      if (doc != null && doc.variables.isNotEmpty) {
        // creation du design par defaut des info
        var elemXuiChild = XUIElementXUI();
        elemXuiChild.xid=xuiCmp.xid;
        elemXuiChild.idRessource = engine.xuiFile.reader?.id;
        DicoOrdered<XUIDesign> curDesign = DicoOrdered();
        engine.xuiFile.designs[xuiCmp.xid] = curDesign;
        curDesign.add(XUIDesign(elemXuiChild, MODE_ALL));

        for (var variable in doc.variables) {
          // affecte les valeur par defaut
          if (variable.def != null) {
            elemXuiChild.propertiesXUI ??= HashMap<String, XUIProperty>();
            elemXuiChild.propertiesXUI[variable.id] = XUIProperty(variable.def);
          }
        }
      }
    }

    return Future.value(xuidesign);
  }

  XUIDesign _getXUIDesignParent(SlotInfo info, String mode) {
    var addIn = info.elementHTML?.parent?.designBy;
    if (addIn != null) {
      for (var design in addIn) {
        if (mode == null || design.mode == mode) {
          return design;
        }
      }
    }
    return null;
  }

  XUIDesign _getXUIDesign(SlotInfo info, String mode) {
    var addIn = info.elementHTML?.designBy;
    if (addIn != null) {
      for (var design in addIn) {
        if (mode == null || design.mode == mode) {
          return design;
        }
      }
    }
    return null;
  }

  /// gestion du remove
  ///
  UndoAction removeDesign(String xid, String mode, [bool withChild = true]) {
    return moveDesign(xid, mode, null, withChild);
  }

  UndoAction moveDesign(String xid, String mode, String moveToXid,
      [bool withChild = true]) {
    SlotInfo info = engine.getSlotInfo(xid, xid);
    if (info == null) {
      throw "xid inconnu $xid";
    }
    // recherche du parent
    var design = _getXUIDesignParent(info, mode);

    if (design != null) {
      var xidParent = design.elemXUI.xid;
      bool hasText = false;
      int nbChildNoText = 0;
      int idx = 0;
      int idxToDelete = -1;

      var elemToChange;

      // recherche du child ayant le xid
      if (design.elemXUI.children != null) {
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

        // retire le child
        if (nbChildNoText == 1 && idxToDelete >= 0 && !hasText) {
          elemToChange = design.elemXUI.children.removeAt(idxToDelete);
          design.elemXUI.children = null;
          print("remove all <$xid> on parent <$xidParent>");
        } else if (nbChildNoText >= 0) {
          elemToChange = design.elemXUI.children.removeAt(nbChildNoText);
          print("remove only <$xid> on parent <$xidParent>");
        }
      }

      // supprime la parent si vide
      if (design.elemXUI.isEmpty()) {
        print("delete design parent <$xidParent>");
        engine.xuiFile.designs.remove(xidParent);
      }

      if (moveToXid == null) {
        print("delete design <$xid>");
        engine.xuiFile.designs.remove(xid);
      } else if (elemToChange != null) {
        moveToDesign(xid, moveToXid, mode, elemToChange);
      }
    }

    // supprime les enfants
    if (withChild && moveToXid == null) {
      _removeChild(info.elementHTML, mode);
    }

    return UndoAction();
  }

  void moveToDesign(String xid, String moveToXid, String mode, elemToChange) {
    SlotInfo info = engine.getSlotInfo(moveToXid, moveToXid);
    XUIDesign designMove;
    if (info != null) {
      designMove = _getXUIDesign(info, mode);
    } else {
      for (XUIDesign aDesign in engine.xuiFile.designs[moveToXid].list) {
        if (mode == null || aDesign.mode == mode) {
          designMove = aDesign;
        }
      }
    }

    if (designMove != null && elemToChange != null) {
      print("move <$xid> to <$moveToXid>");
      designMove.elemXUI.children ??= List<XUIElement>();
      designMove.elemXUI.children.add(elemToChange);
    }
  }

  void _removeChild(XUIElementHTML elem, String mode) {
    if (elem.children != null) {
      for (var childHtml in elem.children) {
        if (childHtml is XUIElementHTML) {
          if (childHtml.designBy != null) {
            for (var design in childHtml.designBy) {
              if (mode == null || design.mode == mode) {
                // remode all children
                if (design.elemXUI.children != null) {
                  for (var childDesign in design.elemXUI.children) {
                    if (childDesign is XUIElementXUI &&
                        childDesign.xid != null) {
                      removeDesign(childDesign.xid, mode, false);
                    }
                  }
                }
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
