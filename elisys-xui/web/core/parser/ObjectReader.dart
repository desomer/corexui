
import 'dart:collection';

import '../XUIEngine.dart';
import '../XUIFactory.dart';
import '../element/XUIElement.dart';
import '../element/XUIProperty.dart';
import 'HTMLReader.dart';

class ObjectReader {


  static Future  addObject(dynamic saveDb, XUIEngine xuiEgine) async 
  {
      for (var aDesign in saveDb["design"]) {
        ObjectReader.addObjectDesign(xuiEgine.xuiFile, aDesign);
      }

      for (var anImport in saveDb["import"]) {
        var subReader =
            HTMLReader(anImport["name"], xuiEgine.xuiFile.reader.provider);

        XUIResource subFile = XUIResource(subReader, xuiEgine.xuiFile.context);
        await subFile.parseXUIFile();
        xuiEgine.xuiFile.listImport.add(subFile);
      }

      for (var aCmp in saveDb["component"]) {
        // TODO a faire 

      }

      return Future.value();
  }

    
  static void addObjectDesign(XUIResource res, var aDesign) {
    var designs = res.designs;

    var curDesign = designs[aDesign["xid"]];
    if (curDesign == null) {
      var elemXui = XUIElementXUI();
      elemXui.idRessource = res.reader.id;
      elemXui.xid = aDesign["xid"];
      curDesign = DicoOrdered();
      designs[elemXui.xid!] = curDesign;
      designs[elemXui.xid]!.add(XUIDesign(elemXui, MODE_ALL, 0));
    }
    XUIDesign xuiDesign = curDesign.sort(res.context).first;

    // print(xuiDesign);

    var props = aDesign["props"];
    if (props != null) {
      for (var aProp in props) {
        // creer la propriete vide
        String variable = aProp["id"];
        var value = aProp["val"];
        var binding = aProp["binding"];

        xuiDesign.elemXUI.propertiesXUI ??= HashMap<String, XUIProperty>();
        // if (xuiDesign.elemXUI.propertiesXUI[variable] == null) {
        xuiDesign.elemXUI.propertiesXUI![variable] = (binding == null)
            ? XUIProperty(value)
            : XUIPropertyBinding(value, null, binding);
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




}