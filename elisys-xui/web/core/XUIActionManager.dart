import 'dart:collection';
import 'dart:math';

import 'XUIEngine.dart';
import 'XUIFactory.dart';
import 'element/XUIElement.dart';
import 'element/XUIProperty.dart';
import 'parser/HTMLReader.dart';

class XUICloneDico {
  var dico = HashMap<String, XUICloneDicoItem>();
  // List<XUICloneDicoItem> stack = [];

  add(XUICloneDicoItem item) {
    dico[item.xidSrc] = item;
    //   stack.add(item);
  }
}

class XUICloneDicoItem {
  String xidSrc;
  String xidDest;
  String xidNew;

  XUICloneDicoItem(this.xidSrc, this.xidDest, this.xidNew);
}

class XUIActionManager {
  XUIEngine engine;

  XUIActionManager(this.engine);

  /// ajoute un nouveau composant  (html)
  ///     affecte les valeurs par defaut
  Future<XUIElementXUI> addDesign(String xid, String html) async {
    XUIResource res = XUIResource(null, engine.xuiFile.context);

    XUIElementXUI xuidesign = await HTMLReader(
            engine.xuiFile.reader.id, engine.xuiFile.reader.provider)
        .parseString(html, res);

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
        bool addDesignDefaut = false;
        for (var variable in doc.variables) {
          // affecte les valeur par defaut
          if (variable.def != null) {
            elemXuiChild.propertiesXUI ??= HashMap<String, XUIProperty>();
            elemXuiChild.propertiesXUI[variable.id] = XUIProperty(variable.def);
            addDesignDefaut = true;
          }
        }
        if (addDesignDefaut) {
          elemXuiChild.xid = xuiCmp.xid;
          elemXuiChild.idRessource = engine.xuiFile.reader?.id;
          DicoOrdered<XUIDesign> curDesign = DicoOrdered();
          engine.xuiFile.designs[xuiCmp.xid] = curDesign;
          curDesign.add(XUIDesign(elemXuiChild, MODE_ALL));
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

  String getNewXid(String xidParent, String nameCmp) {
    var d = DateTime.now().millisecondsSinceEpoch.toString();
    d += Random().nextInt(100).toString();

    var idxUUID = xidParent.indexOf("_");
    var pxid = idxUUID == -1 ? xidParent : (xidParent.substring(0, idxUUID));
    var ret = pxid + "-" + nameCmp.replaceFirst("xui-", "") + "_" + d;
    return ret;
  }

  UndoAction cloneDesign(XUICloneDicoItem cloneInfo, String mode) {
    SlotInfo infoSrc = engine.getSlotInfo(cloneInfo.xidSrc, cloneInfo.xidSrc);
    if (infoSrc != null) {
      cloneInfo.xidNew = getNewXid(cloneInfo.xidDest, infoSrc.implement);

      print("**** start clone "+ cloneInfo.xidSrc +
          " => " +
          cloneInfo.xidNew +
          " to " +
          cloneInfo.xidDest);
      addClone(infoSrc, cloneInfo, mode);

      // gestion des enfant
      XUICloneDico cloneDico = XUICloneDico();
      cloneDico.add(cloneInfo);
      _cloneChildHtml(cloneDico, infoSrc.elementHTML, mode);
    }
    return null;
  }

  void addClone(SlotInfo infoSrc, XUICloneDicoItem cloneInfo, String mode) {
    var tag = infoSrc.implement;

    // ajoute un xuidesign sur le parent pour ajouter le child
    XUIElementXUI xuiElem = XUIElementXUI();
    xuiElem.xid = cloneInfo.xidDest;
    xuiElem.idRessource = engine.xuiFile.reader.id;
    XUIElementXUI child = XUIElementXUI();
    child.idRessource = engine.xuiFile.reader.id;
    child.xid = cloneInfo.xidNew;
    child.tag = tag;
    xuiElem.children ??= [];
    xuiElem.children.add(child);
    engine.xuiFile.designs[cloneInfo.xidDest] ??= DicoOrdered();
    engine.xuiFile.designs[cloneInfo.xidDest].add(XUIDesign(xuiElem, MODE_ALL));

    // var listDesign = engine.xuiFile.designs[xid];
    // var xuiDesign = listDesign.sort(engine.xuiFile.context).first;
    // XUIElementXUI xuiElemDesignSrc = xuiDesign.elemXUI;
    // xuiElemDesignSrc.propertiesXUI;

    //clone du design (les propertiesXUI)  en ajoutant un xuidesign sur le child
    XUIDesign design = _getXUIDesign(infoSrc, mode);
    if (design != null) {
      if (design.elemXUI.propertiesXUI != null) {
        XUIElementXUI xuiElem = XUIElementXUI();
        xuiElem.xid = cloneInfo.xidNew;
        xuiElem.idRessource = engine.xuiFile.reader.id;
        engine.xuiFile.designs[cloneInfo.xidNew] ??= DicoOrdered();
        engine.xuiFile.designs[cloneInfo.xidNew]
            .add(XUIDesign(xuiElem, MODE_ALL));

        xuiElem.propertiesXUI = HashMap();
        design.elemXUI.propertiesXUI.forEach((k, v) {
          XUIProperty cloneProp = XUIProperty(v.content);
          xuiElem.propertiesXUI[k] = cloneProp;
        });
      }
    }
  }

  void _cloneChildHtml(XUICloneDico dico, XUIElementHTML elem, String mode) {
    if (elem.children != null) {
      for (var childHtml in elem.children) {
        if (childHtml is XUIElementHTML) {
          //pas les commentaire
          if (childHtml.designBy != null) {
            for (var design in childHtml.designBy) {
              if (mode == null || design.mode == mode) {
                // clone all children ajouter par des xuidesign
                if (design.elemXUI.children != null) {
                  for (var childDesign in design.elemXUI.children) {
                    if (childDesign is XUIElementXUI &&
                        childDesign.xid != null) {
                      doClone(dico, design.elemXUI, childDesign, mode);
                    }
                  }
                } else {
                  // cas des enfants (designable) ajouter par les parent sans design (ex: xui-title-1 dans xui-list-item-1)
                  print("****** test doCloneOnlyDesign " + design.elemXUI.xid);
                  //SlotInfo info = engine.getSlotInfo(design.elemXUI.xid, design.elemXUI.xid);
                  //SlotInfo infoParent = engine.getSlotInfo(info.parentXid, info.parentXid);
                  doCloneOnlyDesign(dico, design.elemXUI, mode);
                }
              }
            }
          }
          _cloneChildHtml(dico, childHtml, mode);
        }
      }
    }
  }

  void doCloneOnlyDesign(XUICloneDico dico, XUIElementXUI parent, String mode) {
    var idxParentStartNum = parent.xid.indexOf("_");
    var idxParentEndNum = parent.xid.indexOf("-", idxParentStartNum);

    if (idxParentEndNum==-1)
    {
      // ne provient pas d'un slot 
      return;
    }

    var xidSrc = parent.xid.substring(0, idxParentEndNum);
    var slotNameSuffix = parent.xid.substring(xidSrc.length);
    var newIDSlot = dico.dico[xidSrc].xidNew + slotNameSuffix;
    var xidClone = parent.xid;
    
    print("****** doCloneOnlydesign  xidSrc=<" + xidClone + "> xidNew=<"+newIDSlot+"> " + slotNameSuffix);
    XUICloneDicoItem cloneInfo = XUICloneDicoItem(xidClone, null, newIDSlot);
    dico.add(cloneInfo);

    SlotInfo infoSrc = engine.getSlotInfo(cloneInfo.xidSrc, cloneInfo.xidSrc);
    //clone du design (les propertiesXUI)  en ajoutant un xuidesign
    XUIDesign design = _getXUIDesign(infoSrc, mode);
    if (design != null) {
      if (design.elemXUI.propertiesXUI != null) {
        XUIElementXUI xuiElem = XUIElementXUI();
        xuiElem.xid = cloneInfo.xidNew;
        xuiElem.idRessource = engine.xuiFile.reader.id;
        engine.xuiFile.designs[cloneInfo.xidNew] ??= DicoOrdered();
        engine.xuiFile.designs[cloneInfo.xidNew]
            .add(XUIDesign(xuiElem, MODE_ALL));

        xuiElem.propertiesXUI = HashMap();
        design.elemXUI.propertiesXUI.forEach((k, v) {
          XUIProperty cloneProp = XUIProperty(v.content);
          xuiElem.propertiesXUI[k] = cloneProp;
        });
      }
    }
  }

  void doClone(XUICloneDico dico, XUIElementXUI parent,
      XUIElementXUI srcElem, String mode) {

    //SlotInfo info = engine.getSlotInfo(childDesign.xid, childDesign.xid);
    // var design = _getXUIDesignParent(info, mode);

    //********** calcul du slotName a partir du parent *************
    var idxParentStartNum = parent.xid.indexOf("_");    // ex : parent_1321132132-slot
    var idxParentEndNum = parent.xid.indexOf("-", idxParentStartNum);

    var xidParentSansSlot = parent.xid.substring(0, idxParentEndNum);  // parent_1321132132
    var slotNameSuffix = parent.xid.substring(xidParentSansSlot.length);  // -slot
    
    /***************************************************************/

    var newIDSlot = dico.dico[xidParentSansSlot].xidNew + slotNameSuffix;
    var xidClone = srcElem.xid;
    var tagClone = srcElem.tag;

    XUICloneDicoItem cloneInfo = XUICloneDicoItem(xidClone, newIDSlot, null);
    cloneInfo.xidNew = getNewXid(newIDSlot, tagClone);
    dico.add(cloneInfo);

    print("****** doClone xidSrc=<" + xidClone + "> xidDesc=<"+newIDSlot+"> xidNew=" + cloneInfo.xidNew +  "(" +
        tagClone +
        ")");

    SlotInfo infoSrc = engine.getSlotInfo(cloneInfo.xidSrc, cloneInfo.xidSrc);
    addClone(infoSrc, cloneInfo, mode);
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
          print("*****  remove only <$xid> on parent <$xidParent>");
          elemToChange = design.elemXUI.children.removeAt(nbChildNoText);
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
    }

    if (designMove == null) {
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
                } else {
                  print("removeChild design " + design.elemXUI.xid);
                  engine.xuiFile.designs.remove(design.elemXUI.xid);
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
