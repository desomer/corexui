import 'XUIConfigManager.dart';
import 'XUIEngine.dart';
import 'XUIJSInterface.dart';

class XUISlotTreeManager {
  XUIEngine engine;

  XUISlotTreeManager(this.engine);

  List getSlotTree() {
    TreeSlotBuilder treeSlotBuilder = TreeSlotBuilder();
    var mapSlotInfo = engine.mapSlotInfo;

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

  TreeSlot displaySlot(TreeSlotBuilder treeSlotBuilder, SlotInfo slotInfo,
      int tab, TreeSlot? parent) {
    var aTreeSlot = TreeSlot();

    var docInfo = engine.docInfo;

    treeSlotBuilder.nb++;
    aTreeSlot.id = slotInfo.xid ?? treeSlotBuilder.nb.toString();

    //ts.name = slot.xid+" <"+(slot.slotname??"")+">";
    aTreeSlot.name = slotInfo.slotname ?? (slotInfo.implement ?? slotInfo.xid!);
    aTreeSlot.icon = "mdi-web";

    if (slotInfo.docId != null) {
      if (slotInfo.slotname == null && docInfo[slotInfo.docId] != null) {
        aTreeSlot.name = docInfo[slotInfo.docId]!.name ??
            "no slot name"; // affecte le nom du composant si pas de slotName
        aTreeSlot.icon = docInfo[slotInfo.docId]!.icon ?? "mdi-web";
      } else {
        aTreeSlot.icon = (docInfo[slotInfo.docId]?.icon) ?? "mdi-web";
      }
    }

    bool isSlot = slotInfo.implement == TAG_SLOT;
    bool isFlow = slotInfo.implement == "xui-flow";
    bool isNoDisplay = isSlot || isFlow;

    var pathTo = slotInfo.elementHTML?.propertiesXUI?["topath"];
    if (pathTo != null) {
      var ret =
          slotInfo.elementHTML!.calculatePropertyXUI(pathTo.content, null);
      aTreeSlot.toPath = ret.toString();
      isNoDisplay = false;
      isSlot = false;
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

      s = s +
          "# " +
          slotInfo.xid! +
          " <" +
          (slotInfo.slotname ?? "") +
          ">  " +
          (aTreeSlot.toPath);
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
              !item.elementHTML!.isXUIIF(engine)) &&
          slotInfo.xid != XUI_COPYZONE_SLOT) {
        var child = displaySlot(treeSlotBuilder, item, tab + 1, aTreeSlot);

        if (isNoDisplay) {
          // n'affiche pas les slot
          if (parent!.children == null) {
            parent.children = [];
          }
          child.name = child.name +
              " (" +
              aTreeSlot.name +
              ")"; //affecte le nom du slot au enfant
          if (!child.isSlot) {
            parent.children!.add(child);
            child.parent = parent;
          } else {
            parent.children!.addAll(child.children ?? []);
            parent.children!.forEach((element) {
              (element as TreeSlot).parent = parent;
            });
          }
        } else {
          if (aTreeSlot.children == null) {
            aTreeSlot.children = [];
          }
          if (!child.isSlot) {
            aTreeSlot.children!.add(child);
            child.parent = aTreeSlot;
          } else {
            aTreeSlot.children!.addAll(child.children ?? []);
            aTreeSlot.children!.forEach((element) {
              (element as TreeSlot).parent = aTreeSlot;
            });
          }
        }
      }
    }
    aTreeSlot.isSlot = isSlot;

    return aTreeSlot;
  }
}

class TreeSlotBuilder {
  List<TreeSlot> tree = [];
  int nb = 0;
}
