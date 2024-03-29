// ignore_for_file: file_names
import 'dart:collection';
import 'dart:math';

import 'XUIConfigManager.dart';
import 'XUIEngine.dart';
import 'XUIFactory.dart';
import 'element/XUIElement.dart';
import 'element/XUIProperty.dart';
import 'parser/HTMLReader.dart';

///------------------------------------------------------------------------------------
class XUIActionManager {
  XUIEngine engine;

  XUIActionManager(this.engine);

  ///------------------------------------------------------------------------------------
  /// change une property de design
  Future changeProperty(
      String xid, String variable, dynamic value, String? bind) async {
    if (XUIConfigManager.verboseChange) {
      XUIConfigManager.printc('changeProperty $xid a changer lattribut <$variable> par <$value>  bind $bind');
    }

    var listDesign = engine.xuiFile.designs[xid];
    if (listDesign == null) {
      engine.addXUIDesignEmpty(xid);
      listDesign = engine.xuiFile.designs[xid];
    }

    final xuiDesign = listDesign!.sort(engine.xuiFile.context).first;

    if (bind==MODE_SET_PROP_NODOC)
    { // gestion des properties sans documentation
      var elemXui = xuiDesign.elemXUI;
      if (elemXui.propertiesXUI![variable] == null) {  
            elemXui.propertiesXUI![variable] = XUIProperty(null);
      }
      elemXui.propertiesXUI![variable]!.content = value;
      return Future.value();
    }

    // gestion par variable avec une documentation 
    List<DesignInfo> designs = engine.getDesignInfo(xid, xid, false);
    for (var design in designs) {
      DocInfo? doc = design.docInfo;

      if (doc != null && doc.variables.isNotEmpty) {
        for (var aVariable in doc.variables) {
          if (aVariable.id == variable) {
            if (XUIConfigManager.verboseChange) {
              XUIConfigManager.printc(
                  "changeProperty variable xui <${doc.xid}> var <${aVariable.id}> def ${aVariable.def} editor ${aVariable.editor} ");
            }

            bool addValue = true;
            bool removeValue = false;
            bool withBinding = false;
            var elemXui = xuiDesign.elemXUI;

            // test les bool
            if ((aVariable.editor?.startsWith("bool")??false) && aVariable.def == null) {
              if (value == false && elemXui.propertiesXUI != null) {
                // vide la valeur
                removeValue = true;
                addValue = false;
              }
            }

            // teste si champs vider par la croix (null) ou value=""
            if (addValue &&
                (value == null || value == "") &&
                elemXui.propertiesXUI != null) {
              if ((aVariable.editor == "text" || aVariable.editor == "int") &&
                  aVariable.def != null) {
                value = aVariable.def; // affecte la valeur par defaut
              } else {
                removeValue = true;
                addValue = false;
              }
            }

            if (bind != null && bind != "") {
              withBinding = true;
              addValue = true;
            }

            if (removeValue) {
              if (XUIConfigManager.verboseChange) {
                XUIConfigManager.printc("changeProperty : retire la property");
              }
              elemXui.propertiesXUI!.remove(variable);
            }

            if (addValue) {
              // creer la propriete vide
              elemXui.propertiesXUI ??= HashMap<String, XUIProperty>();
              if (elemXui.propertiesXUI![variable] == null && !withBinding) {
                elemXui.propertiesXUI![variable] = XUIProperty(null);
              }
              if (elemXui.propertiesXUI![variable] == null && withBinding) {
                elemXui.propertiesXUI![variable] =
                    XUIPropertyBinding(null, null, null);
              }
              
              if (!(elemXui.propertiesXUI![variable] is XUIPropertyBinding) &&
                  withBinding) {
                elemXui.propertiesXUI![variable] =
                    XUIPropertyBinding(null, null, null);
              }
              if (elemXui.propertiesXUI![variable] is XUIPropertyBinding &&
                  !withBinding) {
                elemXui.propertiesXUI![variable] = XUIProperty(null);
              }
              // affecte la prop
              elemXui.propertiesXUI![variable]!.content = value;
              if (withBinding) {
                (elemXui.propertiesXUI![variable] as XUIPropertyBinding)
                    .binding = bind!;
              }
            }
          }
        }
      }

      if (xuiDesign.elemXUI.isEmpty()) {
        print("delete design <$xid>");
        engine.xuiFile.designs.remove(xid);
      }
    }

    return Future.value();
  }

  ///------------------------------------------------------------------------------------
  /// ajoute un nouveau composant  (html)
  ///     affecte les valeurs par defaut
  Future<XUIElementXUI> addDesign(String? xid, String html) async {
    final reader =
        HTMLReader(engine.xuiFile.reader.id as String, engine.xuiFile.reader.provider);
    final XUIResource res = XUIResource(reader, engine.xuiFile.context);
    reader.id=null; // pas ressource de type fichier

    final XUIElementXUI xuidesign = await reader.parseString(html, res) as XUIElementXUI;

    if (xid != null) {
      xuidesign.xid = xid;
      engine.xuiFile.designs[xid] ??= DicoOrdered();
      engine.xuiFile.designs[xid]!.add(XUIDesign(xuidesign, MODE_ALL, 0));
    }

    if (xuidesign.children != null) {
      XUIElementXUI xuiCmp = xuidesign.children!.first as XUIElementXUI;
      DocInfo? doc = engine.docInfo[xuiCmp.tag];
      if (doc != null && doc.variables.isNotEmpty) {
        // creation du design par defaut des info
        var elemXuiChild = XUIElementXUI();
        bool addDesignDefaut = false;
        for (var variable in doc.variables) {
          // affecte les valeur par defaut
          if (variable.def != null) {
            elemXuiChild.propertiesXUI ??= HashMap<String, XUIProperty>();
            elemXuiChild.propertiesXUI![variable.id] =
                XUIProperty(variable.def);
            addDesignDefaut = true;
          }
        }
        if (addDesignDefaut) {
          elemXuiChild.xid = xuiCmp.xid;
          elemXuiChild.idRessource = engine.xuiFile.reader.id;
          DicoOrdered<XUIDesign> curDesign = DicoOrdered();
          engine.xuiFile.designs[xuiCmp.xid!] = curDesign;
          curDesign.add(XUIDesign(elemXuiChild, MODE_ALL, 0));
        }
      }
    }

    return Future.value(xuidesign);
  }

  XUIDesign? _getXUIDesignParent(SlotInfo info, String? mode) {
    var addIn = info.elementHTML!.parent?.designBy;
    if (addIn != null) {
      for (var design in addIn) {
        if (mode == null || design.mode == mode) {
          return design;
        }
      }
    }
    return null;
  }

  XUIDesign? _getXUIDesign(SlotInfo info, String? mode) {
    var addIn = info.elementHTML!.designBy;
    if (addIn != null) {
      for (var design in addIn) {
        if (mode == null || design.mode == mode) {
          return design;
        }
      }
    }
    return null;
  }

  String _getNewXid(String xidParent, String nameCmp) {
    var d = DateTime.now().millisecondsSinceEpoch.toString();
    d += Random().nextInt(100).toString();

    var idxUUID = xidParent.indexOf("_");
    var pxid = idxUUID == -1 ? xidParent : (xidParent.substring(0, idxUUID));
    var ret = pxid + "-" + nameCmp.replaceFirst("xui-", "") + "_" + d;
    return ret;
  }

  /*************************************************************************************************/
  XUIElementXUI _getOrCreateDesignElem(String xidDest) {
    late XUIElementXUI xuiElem;
    if (engine.xuiFile.designs[xidDest]!=null && engine.xuiFile.designs[xidDest]!.list.length>0 )
    {
        xuiElem=engine.xuiFile.designs[xidDest]!.list[0].elemXUI;
    }
    else
    {
    // ajoute un xuidesign sur le parent pour ajouter le child
      xuiElem = XUIElementXUI();
      xuiElem.xid = xidDest;
      xuiElem.idRessource = engine.xuiFile.reader.id;
      engine.xuiFile.designs[xidDest] ??= DicoOrdered();
      engine.xuiFile.designs[xidDest]!
          .add(XUIDesign(xuiElem, MODE_ALL, 0));
    }
    return xuiElem;
  }

  /*************************************************************************************************/
  UndoAction? cloneDesign(XUICloneDicoItem cloneInfo, String? mode) {
    SlotInfo? infoSrc = engine.getSlotInfo(cloneInfo.xidSrc, cloneInfo.xidSrc);
    if (infoSrc != null) {
      cloneInfo.xidNew = _getNewXid(cloneInfo.xidDest!, infoSrc.implement!);

      print("**** start clone by html crawl " +
          cloneInfo.xidSrc +
          " => new " +
          cloneInfo.xidNew! +
          " to dest " +
          cloneInfo.xidDest!);
      _addClone(infoSrc, cloneInfo, mode);

      // gestion des enfant
      XUICloneDico cloneDico = XUICloneDico();
      cloneDico.add(cloneInfo);
      _cloneChildHtml(cloneDico, infoSrc.elementHTML!, mode);
    }
    return null;
  }

  void _addClone(SlotInfo infoSrc, XUICloneDicoItem cloneInfo, String? mode) {
    var tag = infoSrc.implement;

    print("**** _addClone implement " + tag! + " src= "+
    cloneInfo.xidSrc +
    " => new " +
    cloneInfo.xidNew! +
    " to dest " +
    cloneInfo.xidDest!);

    XUIElementXUI xuiDesignElem = _getOrCreateDesignElem(cloneInfo.xidDest!);

    XUIElementXUI child = XUIElementXUI();
    child.idRessource = engine.xuiFile.reader.id;
    child.xid = cloneInfo.xidNew!;
    child.tag = tag;
    xuiDesignElem.children ??= [];
    xuiDesignElem.children!.add(child);

    //clone du design (les propertiesXUI)  en ajoutant un xuidesign sur le child
    XUIDesign? design = _getXUIDesign(infoSrc, mode);
    if (design != null) {
      if (design.elemXUI.propertiesXUI != null) {

        print("<_addClone> copie prop from " + infoSrc.xid! + " to " + cloneInfo.xidNew!); 

        XUIElementXUI xuiDesignElem = _getOrCreateDesignElem(cloneInfo.xidNew!);
        _cloneProp(xuiDesignElem, design);
      }
    }
  }

  void _cloneProp(XUIElementXUI xuiDesignElem, XUIDesign design) {
    xuiDesignElem.propertiesXUI = HashMap();
    design.elemXUI.propertiesXUI!.forEach((k, v) {
      if (v is XUIPropertyBinding)
      {
        XUIProperty cloneProp = XUIPropertyBinding(v.content, v.namespace, v.binding);
        xuiDesignElem.propertiesXUI![k] = cloneProp;
      }
      else
      {
        XUIProperty cloneProp = XUIProperty(v.content);
        xuiDesignElem.propertiesXUI![k] = cloneProp;
      }
    });
  }

  void _cloneChildHtml(XUICloneDico dico, XUIElementHTML elemHTML, String? mode) {
   // print("_cloneChildHtml on src" + (elemHTML.originElemXUI?.xid??"?") ) ; 

    if (elemHTML.originElemXUI?.xid!=null && elemHTML.designBy!=null)
    {
       for (var design in elemHTML.designBy!) {
              if (mode == null || design.mode == mode) {
                _doCloneOnlyDesign(dico, design.elemXUI , mode);
              }
          }
    }

    if (elemHTML.children != null) {
      for (var childHtml in elemHTML.children!) {
        if (childHtml is XUIElementHTML) {
          
          //pas les commentaire
          if (childHtml.designBy != null) {
            for (var design in childHtml.designBy!) {
              if (mode == null || design.mode == mode) {
                // clone all children ajouter par des xuidesign
                if (design.elemXUI.children != null) {
                  for (var childDesign in design.elemXUI.children!) {
                    if (childDesign is XUIElementXUI &&
                        childDesign.xid != null) {
                      _doCloneAndCalcXID(dico, design.elemXUI, childDesign, mode);
                    }
                  }
                } // else {
                  // cas des enfants (designable) ajouter par les parent sans design (ex: xui-title-1 dans xui-list-item-1)
                /////////////////////   print("****** _cloneChildHtml doCloneOnlyDesign " + design.elemXUI.xid!);
                  //SlotInfo info = engine.getSlotInfo(design.elemXUI.xid, design.elemXUI.xid);
                  //SlotInfo infoParent = engine.getSlotInfo(info.parentXid, info.parentXid);
                 // _doCloneOnlyDesign(dico, design.elemXUI, mode);
              //  }
              }
            }
          }

          // continue le crawl de l'html
          _cloneChildHtml(dico, childHtml, mode);
        }
      }
    }
  }

  void _doCloneOnlyDesign(
      XUICloneDico dico, XUIElementXUI elemSrc, String? mode) {
    var idxParentStartNum = elemSrc.xid!.indexOf("_");
    var idxParentEndNum = elemSrc.xid!.indexOf("-", idxParentStartNum);

    if (idxParentEndNum == -1) {
      // ne provient pas d'un slot
       print("******  doCloneOnlydesign no slot  xidSrc=<"+ elemSrc.xid! +">");
      return;
    }

    var xidSrc = elemSrc.xid!.substring(0, idxParentEndNum);
    var slotNameSuffix = elemSrc.xid!.substring(xidSrc.length);
    var newIDSlot = dico.dico[xidSrc]!.xidNew! + slotNameSuffix;
    var xidClone = elemSrc.xid;

    print("****** doCloneOnlydesign  xidSrc=<" +
        xidClone! +
        "> xidNew=<" +
        newIDSlot +
        "> " +
        slotNameSuffix);

    XUICloneDicoItem cloneInfo = XUICloneDicoItem(xidClone, null, newIDSlot);
    dico.add(cloneInfo);

    SlotInfo infoSrc = engine.getSlotInfo(cloneInfo.xidSrc, cloneInfo.xidSrc)!;
    //clone du design (les propertiesXUI)  en ajoutant un xuidesign
    XUIDesign? design = _getXUIDesign(infoSrc, mode);
    if (design != null) {
      if (design.elemXUI.propertiesXUI != null) {

        print("<_doCloneOnlyDesign> copie prop from " + infoSrc.xid! + " to " + cloneInfo.xidNew!); 

        XUIElementXUI xuiDesignElem = _getOrCreateDesignElem(cloneInfo.xidNew!);
        _cloneProp(xuiDesignElem, design);

      }
    }
  }

  void _doCloneAndCalcXID(XUICloneDico dico, XUIElementXUI parent, XUIElementXUI srcElem,
      String? mode) {
    //SlotInfo info = engine.getSlotInfo(childDesign.xid, childDesign.xid);
    // var design = _getXUIDesignParent(info, mode);

    //********** calcul du slotName a partir du parent *************
    var idxParentStartNum =
        parent.xid!.indexOf("_"); // ex : parent_1321132132-slot
    var idxParentEndNum = parent.xid!.indexOf("-", idxParentStartNum);

    var xidParentSansSlot =
        parent.xid!.substring(0, idxParentEndNum); // parent_1321132132
    var slotNameSuffix =
        parent.xid!.substring(xidParentSansSlot.length); // -slot

    /***************************************************************/

    var newIDSlot = dico.dico[xidParentSansSlot]!.xidNew! + slotNameSuffix;
    var xidClone = srcElem.xid;
    var tagClone = srcElem.tag!;

    XUICloneDicoItem cloneInfo = XUICloneDicoItem(xidClone!, newIDSlot, null);
    cloneInfo.xidNew = _getNewXid(newIDSlot, tagClone);
    dico.add(cloneInfo);

    print("****** doClone xidSrc=<" +
        xidClone +
        "> xidDesc=<" +
        newIDSlot +
        "> xidNew=" +
        cloneInfo.xidNew! +
        "(" +
        tagClone +
        ")");

    SlotInfo? infoSrc = engine.getSlotInfo(cloneInfo.xidSrc, cloneInfo.xidSrc);
    if (infoSrc!=null) {
      _addClone(infoSrc, cloneInfo, mode);
    }
  }
  /************************************************************************************************ */


  ///------------------------------------------------------------------------------------
  UndoAction removeDesign(String xid, String? mode, [bool withChild = true]) {
    return moveDesign(xid, mode, null, withChild);
  }

  ///------------------------------------------------------------------------------------
  UndoAction moveDesign(String xid, String? mode, String? moveToXid, [bool withChild = true]) {
    SlotInfo? info = engine.getSlotInfo(xid, xid);

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
        for (var child in design.elemXUI.children!) {
          if (child is XUIElementText && !hasText) {
            hasText = child.content.toString().trim().isNotEmpty;
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
          elemToChange = design.elemXUI.children!.removeAt(idxToDelete);
          design.elemXUI.children = null;
          print("remove all <$xid> on parent <$xidParent>");
        } else if (nbChildNoText >= 0) {
          print("*****  remove only <$xid> on parent <$xidParent>");
          elemToChange = design.elemXUI.children!.removeAt(nbChildNoText);
        }
      }

      // supprime le parent si vide
      if (design.elemXUI.isEmpty()) {
        print("delete design parent <$xidParent>");
        engine.xuiFile.designs.remove(xidParent);
      }

      if (moveToXid == null) {
        print("delete design <$xid>");
        engine.xuiFile.designs.remove(xid);
      } else if (elemToChange != null) {
        _moveToDesign(info, xid, moveToXid, mode, elemToChange);
      }  else {
        print("moveDesign parent design " + design.elemXUI.xid!);    
        // move le parent si l'enfant ne bouge pas (ex : 1 slot)
        return moveDesign(design.elemXUI.xid!, mode, moveToXid, withChild);
      }
    }
    else
    {
      print("moveDesign un slot design");    
      var pXid = engine.getSlotInfo(xid, xid)?.parentXid;
      if (pXid!=null)
      {
         return moveDesign(pXid, mode, moveToXid, withChild);
      }
    }

    // supprime les enfants
    if (withChild && moveToXid == null) {
      _removeChild(info.elementHTML!, mode);
    }

    return UndoAction();
  }

  void _moveToDesign(SlotInfo infoSrc, String xid, String moveToXid,
      String? mode, elemToChange) {
    SlotInfo? infoDest = engine.getSlotInfo(moveToXid, moveToXid);
    XUIDesign? designMove;
    if (infoDest != null) {
      designMove = _getXUIDesign(infoDest, mode);
    }

    if (designMove == null) {
      for (XUIDesign aDesign in engine.xuiFile.designs[moveToXid]!.list) {
        if (mode == null || aDesign.mode == mode) {
          designMove = aDesign;
        }
      }
    }

    if (designMove != null && elemToChange != null) {
      print("moveToDesign add <$xid> to <$moveToXid>");
      designMove.elemXUI.children ??= [];
      designMove.elemXUI.children?.add(elemToChange);

      // change le slotInfo
      // infoSrc.parentXid=moveToXid;
      // infoSrc.elementHTML?.designBy?.clear();
      // infoSrc.elementHTML?.designBy?.add(designMove);
      // if (infoDest!=null) {
      //   infoSrc.elementHTML?.parent=infoDest.elementHTML;
      // }
    }
  }

  void _removeChild(XUIElementHTML elem, String? mode) {
    if (elem.children != null) {
      for (var childHtml in elem.children!) {
        if (childHtml is XUIElementHTML) {
          if (childHtml.designBy != null) {
            for (var design in childHtml.designBy!) {
              if (mode == null || design.mode == mode) {
                // remode all children
                if (design.elemXUI.children != null) {
                  for (var childDesign in design.elemXUI.children!) {
                    if (childDesign is XUIElementXUI &&
                        childDesign.xid != null) {
                      removeDesign(childDesign.xid!, mode, false);
                    }
                  }
                } else {
                  print("removeChild design " + design.elemXUI.xid!);
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

///------------------------------------------------------------------------------------
class UndoAction {}

class XUICloneDico {
  var dico = HashMap<String, XUICloneDicoItem>();

  add(XUICloneDicoItem item) {
    dico[item.xidSrc] = item;
  }
}

class XUICloneDicoItem {
  String xidSrc;
  String? xidDest;
  String? xidNew;

  XUICloneDicoItem(this.xidSrc, this.xidDest, this.xidNew);
}
