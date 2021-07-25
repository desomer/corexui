import 'dart:collection';
import 'dart:convert';

import 'package:synchronized/synchronized.dart';

import './XUIEngine.dart';
import './XUIFactory.dart';
import './XUIJSInterface.dart';
import './parser/HTMLReader.dart';
import './parser/ProviderAjax.dart';
import 'XUIActionManager.dart';
import 'XUIConfigManager.dart';
import 'element/XUIProperty.dart';

class XUIDesignManager {
  XUIEngine? xuiEngine;
  static final lock = Lock(); // gestion du lock car multiple iFrame
  static final _designManager = HashMap<String, XUIDesignManager?>();
  static var cacheTemplateEditor = HashMap<String, String>();

  var listXidChanged = [];

  ///------------------------------------------------------------------------------------------
  static XUIDesignManager getDesignManager(FileDesignInfo fileInfo) {
    if (_designManager[fileInfo.file] == null) {
      //print("create file ${fileInfo.file}");
      _designManager[fileInfo.file] = XUIDesignManager();
    }

    return _designManager[fileInfo.file]!;
  }

  ///------------------------------------------------------------------------------------------
  static void removeDesignManager(FileDesignInfo fileInfo) {
    if (_designManager[fileInfo.file] != null) {
      _designManager[fileInfo.file] = null;
    }
  }

  XUIEngine getXUIEngine()
  {
    return xuiEngine!;
  }

  ///------------------------------------------------------------------------------------------
  /// generation de l'arbre XUIElementHTML avec bufferHtml
  Future<String?> getHtml(XUIContext ctx, String uri, String xid) async {
    await initEngine(uri, ctx);

    //  if (xid == null) {
    //    return null;
    //  }
    
    var bufferHtml = XUIHtmlBuffer();
    await getXUIEngine().toHTMLString(bufferHtml, xid, ctx);
    return Future.value(bufferHtml.html.toString());
  }

  ///------------------------------------------------------------------------------------------
  /// generation de l'arbre XUIElementHTML sans buffer html
  Future initHtml(XUIContext ctx, String uri, String xid) async {
    await initEngine(uri, ctx);

    // if (xid == null) {
    //   return;
    // }

    await getXUIEngine().toHTMLString(null, xid, ctx);
  }

  ///------------------------------------------------------------------------------------------
  /// generation de l'arbre XUIElemXui
  Future initEngine(String uri, XUIContext ctx) async {
    if (xuiEngine == null) {
      await lock.synchronized(() async {
        xuiEngine = XUIEngine();
        var provider = ProviderAjax();
        if (uri.endsWith(".html")) {
          if (XUIConfigManager.verboseInitXUI) {
            XUIConfigManager.printc("initEngine file html : read ${uri}");
          }
          var reader = HTMLReader(uri, provider);
          await getXUIEngine().initialize(reader, ctx);
        }
      });
    }
  }

  ///------------------------------------------------------------------------------------------
  Future addDesign(String id, String template) async {
    return XUIActionManager(getXUIEngine()).addDesign(id, template);
  }

  Future removeDesign(String id, String? modeDelete) async {
    XUIActionManager(getXUIEngine()).removeDesign(id, modeDelete);
  }

  void moveDesign(String id, String? mode, String moveTo) {
    XUIActionManager(getXUIEngine()).moveDesign(id, mode, moveTo);
  }

  String cloneDesign(String id, String idMove, String? mode) {
    var cloneInfo = XUICloneDicoItem(id, idMove, null);
    XUIActionManager(getXUIEngine()).cloneDesign(cloneInfo, mode);
    return id;
  }

  Future changeProperty(String xid, String variable, dynamic value, String? bind) async {
    return XUIActionManager(getXUIEngine()).changeProperty(xid, variable, value, bind);
  }

  void addXUIDesignEmpty(String xid) {
    getXUIEngine().addXUIDesignEmpty(xid);
  }

  ///------------------------------------------------------------------------------------------
  JSDesignInfo getJSComponentInfo(String id, String idslot) {
    String cmp = """<v-list-item v-for="(item, i) in data" :key="i" >
        <v-list-item-icon draggable=true  @dragstart="\$xui.dragStart(item, \$event)">
          <v-icon dense v-text="item.icon"></v-icon>
        </v-list-item-icon>
        <v-list-item-content draggable=true @dragstart="\$xui.dragStart(item, \$event)">
          <v-list-item-title v-text="item.name"></v-list-item-title>
        </v-list-item-content>
      </v-list-item>""";

    var ret = JSDesignInfo();
    ret.bufTemplate.write(
        "<v-list dense class='xui-list-cmp'><v-list-item-group v-model='item' color='primary'>");
    ret.bufTemplate.write(cmp);
    ret.bufTemplate.write("</v-list-item-group></v-list>");

    var listCmp = getXUIEngine().getComponentsFor(id, idslot);
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
    var designs = getXUIEngine().getDesignInfo(id, idslot, true);
    ret.xid = id;
    ret.xidSlot = idslot;

    FileDesignInfo fi = FileDesignInfo();
    fi.file = 'app/cmpDesignPropEditor.html';

    fi.mode = MODE_FINAL;
    var ctx = XUIContext(fi.mode, null);

    int i = 0;
    // boucle sur l'ensemble des couches de widget
    for (var design in designs) {
      //------------------------------------------------------------------
      // gestion de l'entete
      await _getJSDesignHeader(fi, design, ctx, ret);
      //------------------------------------------------------------------
      // gestion des variable du composant du widget
      for (DocVariables varCmp in design.docInfo?.variables ?? const []) {
        String template =
            await _getJSDesignVariableTemplate(varCmp, fi, ctx, i, design);
        ret.bufTemplate.write(template);
        //------------------------------------------------------------------
        _getJSDesignVariableData(varCmp, design, ret, i);
        i++;
      }
      // fin de template
      ret.bufTemplate.write("</div>");
    }

    // calcul du path pour le fil d'ariane
    designs.reversed.forEach((design) {
      if (ret.bufPath.length > 0) ret.bufPath.write(" > ");
      ret.bufPath.write(design.docInfo?.name ?? design.slotInfo.docId);
    });

    return ret;
  }

  void _getJSDesignVariableData(
      DocVariables varCmp, DesignInfo design, JSDesignInfo ret, int i) {
    String extend = "";
    if (varCmp.editor == "combo") {
      extend = ", \"items\":" + varCmp.list!;
    }

    // gestion des valeurs
    var value;
    var BindOfCmp = "";
    if (design.slotInfo.elementHTML?.propertiesXUI != null) {
      var valInCmp =
          (design.slotInfo.elementHTML?.propertiesXUI![varCmp.id]?.content);

      if (design.slotInfo.elementHTML?.propertiesXUI![varCmp.id]
          is XUIPropertyBinding) {
        BindOfCmp = ((design.slotInfo.elementHTML?.propertiesXUI![varCmp.id]
                as XUIPropertyBinding).binding!);
      }

      if (valInCmp != null && varCmp.editor == "bool") {
        value = valInCmp;
      } else if (valInCmp != null) value = jsonEncode(valInCmp.toString());
    }

    bool exist = value != null;
    //-------  gestion valeur par defaut ----------------
    if (value == null && varCmp.editor == "bool") {
      value = (varCmp.def ?? "false");
    }
    if (value == null) {
      value = "\"" + (varCmp.def ?? "") + "\"";
    }
    //--------------------------------------------------

    if (i > 0) {
      ret.bufData.write(",");
    }

    ret.bufData.write("{\"xid\":\"" +
        design.slotInfo.xid! +
        "\",\"variable\":\"" +
        varCmp.id +
        "\",\"label\":\"" +
        varCmp.doc! +
        "\",\"cat\":\"" +
        (varCmp.cat ?? "layout") +
        "\",\"editor\":\"" +
        varCmp.editor! +
        "\", \"value\":" +
        value.toString() +
        ", \"bind\":\"" +
        BindOfCmp.toString() +
        "\", \"value_orig\":" +
        value.toString() +
        ", \"bind_orig\":\"" +
        BindOfCmp.toString() +
        "\", \"exist\":" +
        exist.toString() + 
        extend +
        "}");
  }

  Future<String> _getJSDesignVariableTemplate(DocVariables varCmp,
      FileDesignInfo fi, XUIContext ctx, int i, DesignInfo design) async {
    var keyCache = varCmp.editor;
    var template = cacheTemplateEditor[keyCache];

    if (template == null) {
      if (varCmp.editor == "combo") {
        fi.xid = 'editor-combo';
        // affecte les items a la combobox grace au addProperties
        XUIComponent cmp =
            await getDesignManager(fi)._getXUIComponent(ctx, fi.file, fi.xid);
        cmp.addProperties("items", "data[##idx##].items");
      } else {
        fi.xid = 'editor-' + varCmp.editor!;
      }

      XUIComponent cmp;
      try {
        cmp = await getDesignManager(fi)._getXUIComponent(ctx, fi.file, fi.xid);
      } catch (e, s) {
        XUIConfigManager.printc("pb cmp ${fi.xid} $e $s");
        rethrow;
      }

      cmp.addProperties("value", "data[##idx##].value");
      cmp.addProperties("label", "data[##idx##].label");
      cmp.addProperties("id", "data[##idx##].xid");
      cmp.addProperties("bind", "data[##idx##].bind");
      cmp.addProperties("variable", "data[##idx##].variable");
      // recupere le code html
      template = await getDesignManager(fi).getHtml(ctx, fi.file, fi.xid);

      // insertion dans le cache
      if (XUIConfigManager.verboseEditor) {
        XUIConfigManager.printc(
            "getJSDesignVariableTemplate add cacheTemplateEditor <" +
                keyCache! +
                ">=>" +
                template!);
      }
      cacheTemplateEditor[keyCache!] = template!;
    }

    template = template.replaceAll("##idx##", i.toString());

    return template;
  }

  Future _getJSDesignHeader(FileDesignInfo fi, DesignInfo design,
      XUIContext ctx, JSDesignInfo ret) async {
    var keyCache = 'editor-header';
    var template = cacheTemplateEditor[keyCache];
    // titre du widget
    String? titleCmp = design.docInfo?.name ?? design.slotInfo.docId;
    if (template == null) {
      fi.xid = 'editor-header';

      XUIComponent cmp =
          await getDesignManager(fi)._getXUIComponent(ctx, fi.file, fi.xid);
      cmp.addProperties(
          "selectAction", "\$xui.displaySelectorByXid('##xid##', '##xid##')");

      cmp.addProperties("selectActionClick",
          "\$xui.displayBindingByXid('##xid##', '##xid##')");

      cmp.addProperties("title", "##title##");

      template = await getDesignManager(fi).getHtml(ctx, fi.file, fi.xid);

      if (XUIConfigManager.verboseEditor) {
        XUIConfigManager.printc("****<" + keyCache + ">=>" + template!);
      }
      cacheTemplateEditor[keyCache] = template!;
    }
    titleCmp = titleCmp ?? ("xid = " + design.slotInfo.xid!);
    if (design.slotInfo.slotname != null) {
      titleCmp = titleCmp + " (" + design.slotInfo.slotname! + ")";
    }

    template = template.replaceAll("##xid##", design.slotInfo.xid!);
    template = template.replaceAll("##title##", titleCmp);

    ret.bufTemplate
        .write("<div class='xui-over-prop-xid' id='${design.slotInfo.xid}'>");
    ret.bufTemplate.write(template);
  }

  Future<XUIComponent> _getXUIComponent(
      XUIContext ctx, String uri, String idCmp) async {
    if (xuiEngine == null) {
      await lock.synchronized(() async {
        xuiEngine = XUIEngine();
        var provider = ProviderAjax();
        if (XUIConfigManager.verboseGetXUIComponent) {
          XUIConfigManager.printc(
              "initialize file for getXUIComponent : read ${uri}");
        }
        var reader = HTMLReader(uri, provider);
        await getXUIEngine().initialize(reader, ctx);
      });
    }

    XUIComponent cmp = getXUIEngine().xuiFile.components[idCmp]!.sort(ctx).first;
    return cmp;
  }

  ///------------------------------------------------------------------------------------------

  List getActionsPopup(
      XUIContext ctx, String id, String idslot, String action) {
    List<ObjectAction> ret = [];

    var designs = getXUIEngine().getDesignInfo(id, idslot, true);
    var idx = 0;
    for (var design in designs) {
      idx++;
      if (idx > 5) {
        break;
      }
      bool isSlot = id.startsWith(SLOT_PREFIX);
      /*********************************** */
      if (design.docInfo != null) {
        if (design.docInfo!.xid == "v-tab:xui-tabs") {
          if (idx == 1) {
            // ajout un flow
            ObjectAction act = ObjectAction(
                xid: design.slotInfo.xid!,
                action: "addFlow",
                type: "flow",
                icon: "mdi-table-row",
                title: "Add flow");
            ret.add(act);
          }
          ObjectAction act = ObjectAction(
              xid: design.slotInfo.xid!,
              action: "incNbBefore",
              icon: "mdi-tab",
              type: "tabs",
              title: "Add new Tab (before " + design.slotInfo.slotname! + ")");
          ret.add(act);
          act = ObjectAction(
              xid: design.slotInfo.xid!,
              action: "incNbAfter",
              icon: "mdi-tab",
              type: "tabs",
              title: "Add new Tab (after " + design.slotInfo.slotname!+ ")");
          ret.add(act);
        } else if (design.docInfo!.xid == "xui-no-dom:xui-flow") {
          ObjectAction act = ObjectAction(
              xid: design.slotInfo.xid!,
              action: "incNbBefore",
              type: "flow",
              icon: "mdi-transfer-left",
              title: "Add right (before " + design.slotInfo.slotname! + ")");
          ret.add(act);
          act = ObjectAction(
              xid: design.slotInfo.xid!,
              action: "incNbAfter",
              type: "flow",
              icon: "mdi-transfer-right",
              title: "Add right (after " + design.slotInfo.slotname! + ")");
          ret.add(act);
        } else if (idx == 1 && isSlot) {
          // ajoute un slot
          ObjectAction act = ObjectAction(
              xid: design.slotInfo.xid!,
              action: "addFlow",
              type: "flow",
              icon: "mdi-table-row",
              title: "Add flow");
          ret.add(act);
        } else if (idx == 1 && !isSlot) {
          // ajoute un slot
          ObjectAction act = ObjectAction(
              xid: design.slotInfo.xid!,
              action: "surroundRight",
              type: "flow",
              icon: "mdi-table-row",
              title: "Add right (surroundRight)");
          ret.add(act);
        } else {
          // var ti = (design.docInfo.addRemove ?? "noAddRemove") +
          //     "|" +
          //     (design.slotInfo.slotname ?? "noSlotName") +
          //     "|" +
          //     design.docInfo.xid +
          //     "|" +
          //     design.docInfo.name +
          //     "|" +
          //     design.slotInfo.implement;

          // ObjectAction act = ObjectAction(
          //     xid: design.slotInfo.xid,
          //     action: "addFlow",
          //     icon: "mdi-table-row",
          //     title: ti);
          // ret.add(act);
        }
      }
    }

    List<ObjectAction> retFiltered = [];

    for (var i = 0; i < ret.length; i++) {
      retFiltered.add(ret[i]);
      if (i > 0 &&
          ret[i].action == "incNbBefore" &&
          ret[i].type != "tabs" &&
          retFiltered[i - 1].action == "surroundRight") {
        retFiltered.removeAt(i - 1);
      }
    }

    return retFiltered;
  }
}

///------------------------------------------------------------------------------------------
class JSDesignInfo {
  late String xid;
  late String xidSlot;
  var bufPath = StringBuffer();
  var bufData = StringBuffer();
  var bufTemplate = StringBuffer();
}
