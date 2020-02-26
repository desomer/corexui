import 'dart:collection';
import 'dart:convert';

import 'package:synchronized/synchronized.dart';

import './XUIEngine.dart';
import './XUIFactory.dart';
import './parser/HTMLReader.dart';
import './parser/ProviderAjax.dart';
import 'XUIActionManager.dart';
import 'element/XUIProperty.dart';
import './XUIJSInterface.dart';

class XUIDesignManager {
  XUIEngine xuiEngine;
  static final lock = Lock(); // gestion du lock car multiple iFrame

  static final _designManager = HashMap<String, XUIDesignManager>();
  static XUIDesignManager getDesignManager(FileDesignInfo fileInfo) {
    if (_designManager[fileInfo.file] == null) {
      print("create file ${fileInfo.file}");
      _designManager[fileInfo.file] = XUIDesignManager();
    }

    return _designManager[fileInfo.file];
  }

  ///------------------------------------------------------------------------------------------
  Future<String> getHtml(XUIContext ctx, String uri, String xid) async {
    var bufferHtml = XUIHtmlBuffer();

    await lock.synchronized(() async {
      if (xuiEngine == null) {
        xuiEngine = XUIEngine();
        var provider = ProviderAjax();
        print("initialize file ${uri}");
        var reader = HTMLReader(uri, provider);
        await xuiEngine.initialize(reader, ctx);
      }

      if (xid == null) {
        return null;
      }

      await xuiEngine.toHTMLString(bufferHtml, xid, ctx);
    });

    return Future.value(bufferHtml.html.toString());
  }

  ///------------------------------------------------------------------------------------------
  Future<XUIComponent> getXUIComponent(
      XUIContext ctx, String uri, String idCmp) async {
    await lock.synchronized(() async {
      if (xuiEngine == null) {
        xuiEngine = XUIEngine();
        var provider = ProviderAjax();
        print("initialize file ${uri}");
        var reader = HTMLReader(uri, provider);
        await xuiEngine.initialize(reader, ctx);
      }
    });

    XUIComponent cmp = xuiEngine.xuiFile.components[idCmp].sort(ctx).first;
    return cmp;
  }

  ///------------------------------------------------------------------------------------------
  Future addDesign(String id, String template) async {
    print("add design on ${id}  template ${template}");
    await XUIActionManager(xuiEngine).addDesign(id, template);
    return Future.value();
  }

  void removeDesign(String id, String modeDelete) async {
    XUIActionManager(xuiEngine).removeDesign(id, modeDelete);
  }

  void moveDesign(String id, String modeDelete, String moveTo) {
    XUIActionManager(xuiEngine).moveDesign(id, modeDelete, moveTo);
  }

  ///------------------------------------------------------------------------------------------
  Future changeProperty(String xid, String variable, dynamic value) async {
    print("${xid} a changer l'attribut ${variable} par ${value}");
    var listDesign = xuiEngine.xuiFile.designs[xid];
    if (listDesign == null) {
      await addDesign(xid, "<xui-design></xui-design>");
      listDesign = xuiEngine.xuiFile.designs[xid];
    }

    var xuiDesign = listDesign.sort(xuiEngine.xuiFile.context).first;

    var designs = xuiEngine.getDesignInfo(xid, xid);
    for (var design in designs) {
      DocInfo doc = design.docInfo;
      if (doc != null && doc.variables.isNotEmpty) {
        for (var aVariable in doc.variables) {
          if (aVariable.id == variable) {
            print(
                "var ${aVariable.id} def ${aVariable.def} editor ${aVariable.editor} ");

            // affecte les valeur par defaut
            if (aVariable.editor == "bool" && aVariable.def==null) {
                if ( value == false && xuiDesign.elemXUI.propertiesXUI!=null)
                {
                    // vide la valeur 
                    print("vide la variable bool");
                    xuiDesign.elemXUI.propertiesXUI.remove(variable);
                    return Future.value();
                }
            }

            // creer la propriete vide
            xuiDesign.elemXUI.propertiesXUI ??= HashMap<String, XUIProperty>();
            if (xuiDesign.elemXUI.propertiesXUI[variable] == null) {
              xuiDesign.elemXUI.propertiesXUI[variable] = XUIProperty(null);
            }
            // affecte la prop
            xuiDesign.elemXUI.propertiesXUI[variable].content = value;
          }
        }
      }
    }

    return Future.value();
  }

  ///------------------------------------------------------------------------------------------
  JSDesignInfo getJSComponentInfo(String id, String idslot) {
    String cmp = """<v-list-item v-for="(item, i) in data" :key="i" >
        <v-list-item-icon draggable=true  @dragstart="\$xui.dragStart(item, \$event)">
          <v-icon v-text="item.icon"></v-icon>
        </v-list-item-icon>
        <v-list-item-content draggable=true @dragstart="\$xui.dragStart(item, \$event)">
          <v-list-item-title v-text="item.name"></v-list-item-title>
        </v-list-item-content>
      </v-list-item>""";

    var ret = JSDesignInfo();
    ret.bufTemplate.write(
        "<v-list dense><v-list-item-group v-model='item' color='primary'>");
    ret.bufTemplate.write(cmp);
    ret.bufTemplate.write("</v-list-item-group></v-list>");

    var listCmp = xuiEngine.getComponentsFor(id, idslot);
    var i = 0;
    for (var item in listCmp) {
      if (i > 0) ret.bufData.write(",");
      ret.bufData.write(
          '{"name":"${item.name}", "xid":"${item.xid}", "icon":"${item.icon}" }');
      i++;
    }

    ret.xid = id.startsWith(SLOT_PREFIX) ? idslot : id;
    ret.xidSlot = idslot;

    return ret;
  }

  ///------------------------------------------------------------------------------------------
  Future<JSDesignInfo> getJSDesignInfo(String id, String idslot) async {
    var ret = JSDesignInfo();
    var designs = xuiEngine.getDesignInfo(id, idslot);
    ret.xid = id;
    ret.xidSlot = idslot;

    FileDesignInfo fi = FileDesignInfo();
    fi.file = 'app/cmpDesignEditor.html';

    fi.mode = MODE_FINAL;
    var ctx = XUIContext(fi.mode);

    int i = 0;
    for (var design in designs) {
      var titleCmp = design?.docInfo?.name ?? design.slotInfo.docId;
      fi.xid = 'editor-header';
      XUIComponent cmp =
          await getDesignManager(fi).getXUIComponent(ctx, fi.file, fi.xid);
      cmp.addProperties("selectAction",
          "\$xui.displaySelectorByXid('${design.slotInfo.xid}', '${design.slotInfo.xid}')");
      cmp.addProperties("title", titleCmp);
      String header = await getDesignManager(fi).getHtml(ctx, fi.file, fi.xid);
      ret.bufTemplate.write("<div class='xui-over-prop-xid' id='${design.slotInfo.xid}'>");
      ret.bufTemplate.write(header);

      for (DocVariables varCmp in design?.docInfo?.variables ?? const []) {
        var istr = i.toString();
        String template;
        String extend = "";

        if (varCmp.editor == "bool") {
          fi.xid = 'editor-bool';
        } else if (varCmp.editor == "int") {
          fi.xid = 'editor-int';
        } else if (varCmp.editor == "combo") {
          fi.xid = 'editor-combo';
          XUIComponent cmp =
              await getDesignManager(fi).getXUIComponent(ctx, fi.file, fi.xid);
          cmp.addProperties("items", "data[${istr}].items");
          extend = ", \"items\":" + varCmp.list;
        } else {
          fi.xid = 'editor-text';
        }

        XUIComponent cmp =
            await getDesignManager(fi).getXUIComponent(ctx, fi.file, fi.xid);
        cmp.addProperties("value", "data[${istr}].value");
        cmp.addProperties("label", "data[${istr}].label");
        template = await getDesignManager(fi).getHtml(ctx, fi.file, fi.xid);

        ret.bufTemplate.write(template);
        if (i > 0) ret.bufData.write(",");

        var value;
        if (design.slotInfo.elementHTML?.propertiesXUI != null) {
          var valInCmp =
              (design.slotInfo.elementHTML?.propertiesXUI[varCmp.id]?.content);
          if (valInCmp != null && varCmp.editor == "bool") {
            value = valInCmp;
          } else if (valInCmp != null) value =  jsonEncode(valInCmp.toString());
        }

        bool exist = value != null;
        if (value == null && varCmp.editor == "bool") {
          value = (varCmp.def ?? "false");
        }
        if (value == null) {
          value = "\"" + (varCmp.def ?? "") + "\"";
        }

        ret.bufData.write("{\"xid\":\"" +
            design.slotInfo.xid +
            "\",\"variable\":\"" +
            varCmp.id +
            "\",\"label\":\"" +
            varCmp.doc +
            "\", \"value\":" +
            value.toString() +
            ", \"value_orig\":" +
            value.toString() +
            ", \"exist\":" +
            exist.toString() +
            extend +
            "}");
        i++;
      }

       ret.bufTemplate.write("</div>");
    }

    designs.reversed.forEach((design) {
      if (ret.bufPath.length > 0) ret.bufPath.write(" > ");
      ret.bufPath.write(design.docInfo?.name ?? design.slotInfo.docId);
    });

    return ret;
  }
}

///------------------------------------------------------------------------------------------
class JSDesignInfo {
  String xid;
  String xidSlot;
  var bufPath = StringBuffer();
  var bufData = StringBuffer();
  var bufTemplate = StringBuffer();
}
