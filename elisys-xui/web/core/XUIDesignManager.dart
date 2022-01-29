import 'dart:collection';
import 'dart:convert';
import 'dart:developer';

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

  XUIEngine getXUIEngine() {
    return xuiEngine!;
  }

  ///------------------------------------------------------------------------------------------
  /// generation de l'arbre XUIElementHTML avec bufferHtml
  Future<String?> getHtml(XUIContext ctx, String uri, String xid) async {
    await initEngine(uri, ctx);
    var bufferHtml = XUIHtmlBuffer();
    await getXUIEngine().processPhases(bufferHtml, xid, ctx);
    return Future.value(bufferHtml.html.toString());
  }

  ///------------------------------------------------------------------------------------------
  /// generation de l'arbre XUIElementHTML sans buffer html
  Future initHtml(XUIContext ctx, String uri, String xid) async {
    await initEngine(uri, ctx);
    await getXUIEngine().processPhases(null, xid, ctx);
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

  Future changeProperty(
      String xid, String variable, dynamic value, String? bind) async {
    return XUIActionManager(getXUIEngine())
        .changeProperty(xid, variable, value, bind);
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
  JSDesignInfo getJSDesignValue(String id, String idslot, int deep) {
    var ret = JSDesignInfo();
    var designs = getXUIEngine().getDesignInfo(id, idslot, true);
    ret.xid = id;
    ret.xidSlot = idslot;
    int i = 0;
    var range = designs.getRange(0, deep);
    for (var design in range) {
      for (DocVariables varCmp in design.docInfo?.variables ?? const []) {
        _getJSDesignVariableData(varCmp, design, ret, i);
        i++;
      }
    }
    return ret;
  }

  Future<JSDesignInfo> getJSDesignInfo(
      String id, String idslot, String mode) async {
    var ret = JSDesignInfo();
    var designs = getXUIEngine().getDesignInfo(id, idslot, true);
    ret.xid = id;
    ret.xidSlot = idslot;

    FileDesignInfo fi = FileDesignInfo();
    fi.file = 'app/cmpDesignPropEditor.html';

    fi.mode = MODE_FINAL;
    var ctx = XUIContext(fi.mode);
    ctx.setCause("getJSDesignInfo");

    //------------------------------------------------------------------
    var idxFor = designs.length;
    var hasForIdx = -1;
    var startPath = 0;
    var idx = 0;
    const nb = 10;
    if (designs.length > nb) {   // affiche que nb element
      startPath = idxFor - nb - 1;
    }
    designs.reversed.forEach((design) {

      // calcul du path pour le fil d'ariane et du for
      if (idx == startPath && idx > 0) {
        TreeSlot aSlot = TreeSlot();
        aSlot.name = "...";
        aSlot.id = design.slotInfo.xid!;
        ret.listPath.add(aSlot);
      } else if (idx >= startPath) {
        TreeSlot aSlot = TreeSlot();
        aSlot.name = design.slotInfo.slotname ??
            design.docInfo?.name ??
            design.slotInfo.docId!;
        bool isSlot = design.slotInfo.implement == TAG_SLOT;
        if (isSlot) aSlot.name = "[" + aSlot.name + "]";
        aSlot.id = design.slotInfo.xid!;
        ret.listPath.add(aSlot);
      }

      //-------------- gestion du for
      if (design.slotInfo.mapTag["for"] != null) {
        hasForIdx = idxFor;
      }
      idxFor--;
      //------------------

      idx++;
    });

    //--------------------   LES PATH CHILDREN ------------------------------
    bool displayChild = true;
    // ignore: dead_code
    if (displayChild &&  designs.length > 0 && designs.first.slotInfo.children != null) {
      designs.first.slotInfo.children!.forEach((slotInfo) {
        TreeSlot aSlot = TreeSlot();
        DocInfo? doc = xuiEngine!.docInfo[slotInfo.docId];
        aSlot.name = slotInfo.slotname ?? doc?.name ?? slotInfo.docId!;
        bool isSlot = slotInfo.implement == TAG_SLOT;
        if (isSlot) aSlot.name = "[" + aSlot.name + "]";
        // aSlot.name=aSlot.name+" ["+(slotInfo.implement??"ni")+"]";

        // if (doc?.isConditional() ?? false) {
        //   if (slotInfo.elementHTML?.propertiesXUI != null) {
        //     String? varactive =
        //         (slotInfo.elementHTML?.propertiesXUI![":varactive"]?.content);
        //     aSlot.name = aSlot.name + " [x]";
        //     aSlot.toPath = varactive;
        //   }
        // }
        aSlot.id = slotInfo.xid!;
        ret.listChildPath.add(aSlot);
      });
    }

    //--------------------   LES PATH CONDITIONAL ------------------------------
    getXUIEngine().mapSlotInfo.forEach((key, slotInfo) {
      DocInfo? doc = xuiEngine!.docInfo[slotInfo.docId];
      if (doc?.isConditional() ?? false) {
        TreeSlot aSlot = TreeSlot();
        aSlot.name = slotInfo.slotname ?? doc?.name ?? slotInfo.docId!;
        if (slotInfo.elementHTML?.propertiesXUI != null) {
           String? varactive =
              (slotInfo.elementHTML?.propertiesXUI![":varactive"]?.content);
          aSlot.toPath = varactive;
        }
        aSlot.id = slotInfo.xid!;
        ret.listConditionalPath.add(aSlot);
      }
    });
    //------------------------------------------------------------------

    int nbCmp = 0;
    int i = 0;
    // boucle sur l'ensemble des couches de widget
    for (var design in designs) {

      //print(">>>>> "+(design.slotInfo.implement??"NI")+" > "+(design.docInfo?.variables.length.toString() ?? "0"));
      if (design.slotInfo.implement == TAG_SLOT &&
          (design.docInfo?.variables.length ?? 0) == 0) {
        if (nbCmp==0 && hasForIdx>0) hasForIdx--;
        if (nbCmp>0)  nbCmp++;
        continue;
      }
      //------------------------------------------------------------------
      if (nbCmp == 0 && hasForIdx >= 0) {
        await _getJSDesignFor(fi, design, ctx, ret);
      }
      // gestion de l'entete
      await _getJSDesignHeader(fi, design, ctx, ret);
      //------------------------------------------------------------------
      // gestion des variable du composant du widget
      for (DocVariables varCmp in design.docInfo?.variables ?? const []) {
        bool isStyle = (varCmp.cat == "class" ||
            varCmp.cat == "style" ||
            varCmp.cat == "vstyle");
        bool isEvent =
            (varCmp.cat != null && varCmp.cat.toString().startsWith("event"));

        if (varCmp.cat == "config") {
          continue; // n'affiche pas les prop de config
        }
        if (mode == "design" && (isStyle || isEvent)) {
          continue;
        }
        if (mode == "style" && !isStyle) {
          continue;
        }
        if (mode == "event" && !isEvent) {
          continue;
        }

        String template =
            await _getJSDesignVariableTemplate(varCmp, fi, ctx, i, design);
        ret.bufTemplate.write(template);
        //------------------------------------------------------------------
        _getJSDesignVariableData(varCmp, design, ret, i);
        i++;
      }
      //-----------------------------------------------------------------

      nbCmp++;
      // fin de template
      ret.bufTemplate.write("</div>");

      if (hasForIdx>=0 && nbCmp >= hasForIdx) {
        ret.bufTemplate.write("</div>");
        hasForIdx=-1;
      }
    }

    // if (nbCmp < 3) {
    //   ret.bufTemplate.write("</div>");
    // }

    return ret;
  }

  Future _getJSDesignFor(FileDesignInfo fi, DesignInfo design, XUIContext ctx,
      JSDesignInfo ret) async {
    var keyCache = 'editor-for';
    var template = cacheTemplateEditor[keyCache];

    if (template == null) {
      fi.xid = 'editor-for';

      // XUIComponent cmp =
      //     await getDesignManager(fi)._getXUIComponent(ctx, fi.file, fi.xid);

      template = await getDesignManager(fi).getHtml(ctx, fi.file, fi.xid);

      if (XUIConfigManager.verboseEditor) {
        XUIConfigManager.printc("****<" + keyCache + ">=>" + template!);
      }
      cacheTemplateEditor[keyCache] = template!;
    }

    ret.bufTemplate.write(template);
    ret.bufTemplate.write("<div class='xui-class-for'>");
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
                as XUIPropertyBinding)
            .binding!);
      }

      if (valInCmp != null && (varCmp.editor?.startsWith("bool") ?? false)) {
        value = valInCmp;
      } else if (valInCmp != null) value = jsonEncode(valInCmp.toString());
    }

    bool exist = value != null;
    //-------  gestion valeur par defaut ----------------
    if (value == null && (varCmp.editor?.startsWith("bool") ?? false)) {
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
    String? titleCmp = design.docInfo?.name;
    if (titleCmp == null && design.slotInfo.docId != null) {
      titleCmp = "docID=" + design.slotInfo.docId.toString();
    }

    if (template == null) {
      fi.xid = 'editor-header';

      XUIComponent cmp =
          await getDesignManager(fi)._getXUIComponent(ctx, fi.file, fi.xid);
      cmp.addProperties("selectAction",
          "\$xui.SelectorManager.displaySelectorByXid('##xid##', '##xid##')");

      cmp.addProperties("selectActionClick",
          "\$xui.displayPropActionByXid('##xid##', '##xid##')");

      cmp.addProperties("title", "##title##");

      template = await getDesignManager(fi).getHtml(ctx, fi.file, fi.xid);

      if (XUIConfigManager.verboseEditor) {
        XUIConfigManager.printc("****<" + keyCache + ">=>" + template!);
      }
      cacheTemplateEditor[keyCache] = template!;
    }

    titleCmp = titleCmp ?? ("nodoc xid=" + design.slotInfo.xid.toString());
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

    XUIComponent cmp =
        getXUIEngine().xuiFile.components[idCmp]!.sort(ctx).first;
    return cmp;
  }

  ///------------------------------------------------------------------------------------------

  List getActionsPopup(
       FileDesignInfo fileInfo , String id, String idslot, String action) {
    List<ObjectAction> ret = [];

    var designs = getXUIEngine().getDesignInfo(id, idslot, true);
    var idx = 0; 
    var firstNoSlot = -1; 


    for (var design in designs) {
      idx++;
      if (idx > 7) {
        break;
      }
      bool isSlot = design.slotInfo.slotname!=null;
      bool inSlot = idx<designs.length && designs[idx].slotInfo.slotname!=null; // && (designs[idx].docInfo?.isActionEnable()??true); 

      //print("=============>" + (designs[idx].docInfo?.type??"?"));
      /*********************************** */
      if (design.docInfo != null) {

        if (firstNoSlot==-1 && !isSlot )
            firstNoSlot=idx;

        if (idx==1 && !isSlot)
        {
          // premier non slot
          ObjectAction act = ObjectAction(
              xid: design.slotInfo.xid!,
              action: "class",
              icon: "mdi-palette-swatch-variant",
              type: "class",
              title: "Add classes");
          ret.insert(0, act);
          act = ObjectAction(
              xid: designs[0].slotInfo.xid!,
              action: "",
              icon: "",
              type: "divider",
              title: "");
          ret.insert(1, act);
        }

        if (design.docInfo!.xid == "v-col:xui-row-1") {
          // si rows
          ObjectAction act = ObjectAction(
              xid: design.slotInfo.xid!,
              action: "incNbBefore",
              icon: "mdi-table-column-plus-before",
              type: "row",
              title: "insert column before");
          ret.add(act);
          act = ObjectAction(
              xid: design.slotInfo.xid!,
              action: "incNbAfter",
              icon: "mdi-table-column-plus-after",
              type: "row",
              title: "insert column after");
          ret.add(act);

        } else if ( (design.docInfo!.type?.contains("rows")??false)) {
          // si de type col
          ObjectAction act = ObjectAction(
              xid: design.slotInfo.xid!,
              action: "incNbBefore",
              icon: "mdi-table-row-plus-before",
              type: "col",
              title: "insert row before");
          ret.add(act);
          act = ObjectAction(
              xid: design.slotInfo.xid!,
              action: "incNbAfter",
              icon: "mdi-table-row-plus-after",
              type: "col",
              title: "insert row after");
          ret.add(act);

        }  else if (design.docInfo!.xid == "v-tab:xui-tabs") {
          // si onglet de tab
          if (idx == 1) {
            // ajout un flow si le premier slot est un v-tab
            ObjectAction act = ObjectAction(
                xid: design.slotInfo.xid!,
                action: "addFlow",
                type: "flow",
                icon: "mdi-transfer-right",
                title: "Add slot in "+design.slotInfo.slotname!);
            ret.add(act);
          }

          ObjectAction act = ObjectAction(
              xid: design.slotInfo.xid!,
              action: "incNbBefore",
              icon: "mdi-tab-plus",
              type: "tabs",
              title: "Add new Tab (before " + design.slotInfo.slotname! + ")");
          ret.add(act);
          act = ObjectAction(
              xid: design.slotInfo.xid!,
              action: "incNbAfter",
              icon: "mdi-tab-plus",
              type: "tabs",
              title: "Add new Tab (after " + design.slotInfo.slotname! + ")");
          ret.add(act);
        } 
        //--------------------------------------------------------------
        else if (design.docInfo!.xid == "xui-no-dom:xui-flow") {
          // sur un flow
          ObjectAction act = ObjectAction(
              xid: design.slotInfo.xid!,
              action: "incNbBefore",
              type: "flow",
              icon: "mdi-transfer-left",
              title: "Add slot before in flow");
          ret.add(act);
          act = ObjectAction(
              xid: design.slotInfo.xid!,
              action: "incNbAfter",
              type: "flow",
              icon: "mdi-transfer-right",
              title: "Add slot after in flow");
          ret.add(act);
        }  
        else if (idx == 1 && isSlot) {
          // sur un slot => ajoute un flow 
          ObjectAction act = ObjectAction(
              xid: design.slotInfo.xid!,
              action: "addFlow",
              type: "flow",
              icon: "mdi-transfer-right",
              title: "Add slot in "+design.slotInfo.slotname!);
          ret.add(act);
        } 
        
        if (idx == firstNoSlot) {  
          var info = xuiEngine!.getSlotInfo( design.slotInfo.xid!, design.slotInfo.xid!);
          bool canSurround = info?.elementHTML?.canSurround(fileInfo)??false;

          // sur le premier composant actif mais pas déja dans un flow
          if (inSlot && canSurround && designs[idx].docInfo?.xid != "xui-flow" && designs[idx].docInfo?.xid != "xui-no-dom:xui-flow") {

            // ajoute un slot si pas deja dans un slot de type flow
            addSurroundFlow(design, ret);
          }
        } 
      }
    }
    // --------------------------fin for

    if (designs.length>0)
    {
        bool isSlot = designs[0].slotInfo.slotname!=null;
        if (isSlot)
        {
              ObjectAction act = ObjectAction(
                  xid: designs[0].slotInfo.xid!,
                  action: "addCmp",
                  icon: "mdi-shape-plus",
                  type: "class",
                  title: "choise component");
              ret.insert(0, act);
              act = ObjectAction(
                xid: designs[0].slotInfo.xid!,
                action: "",
                icon: "",
                type: "divider",
                title: "");
              ret.insert(1, act);
        }

        var designFirstNoSlot = designs[firstNoSlot-1];
        isSlot = designFirstNoSlot.slotInfo.slotname!=null;
        var info = xuiEngine!.getSlotInfo( designFirstNoSlot.slotInfo.xid!, designFirstNoSlot.slotInfo.xid!);
        bool canSurround = info?.elementHTML?.canSurround(fileInfo)??false;

        if (canSurround && !isSlot) {
            addSurroundAction(designs, ret, firstNoSlot);
        }
    }

    // analyse des action
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

  void addSurroundFlow(DesignInfo design, List<ObjectAction> ret) {
    
    // ajoute un slot si pas deja dans un slot de type flow
    ObjectAction act = ObjectAction(
        xid: design.slotInfo.xid!,
        action: "surround",
        type: "xui-flow",
        slot : "-col-1",
        icon: "mdi-transfer-left",
        title: "Add slot before in flow"); //+ (designs[idx].docInfo?.xid ?? ""));
    ret.add(act);
    // ajoute un slot si pas deja dans un slot
    act = ObjectAction(
        xid: design.slotInfo.xid!,
        action: "surround",
        type: "xui-flow",
        slot : "-col-0",
        icon: "mdi-transfer-right",
        title: "Add slot after in flow");
    ret.add(act);
  }

  void addSurroundAction(List<DesignInfo> designs, List<ObjectAction> ret, int firstNoSlot) {
    var designFirstNoSlot = designs[firstNoSlot-1];

     ObjectAction act = ObjectAction(
        xid: designs[0].slotInfo.xid!,
        action: "",
        icon: "",
        type: "divider",
        title: "");
    ret.add(act);

    act = ObjectAction(
        xid: designFirstNoSlot.slotInfo.xid!,
        action: "surround",
        type: "xui-if-else",
        slot : "-if",
        icon: "mdi-arrow-decision-auto",
        title: "Is Conditional (If)");
    ret.add(act);

    act = ObjectAction(
        xid: designFirstNoSlot.slotInfo.xid!,
        action: "surround",
        type: "xui-row-1",
        slot : "-col-0",
        icon: "mdi-table-row",
        title: "Surround in row");
    ret.add(act);
    
    act = ObjectAction(
        xid: designFirstNoSlot.slotInfo.xid!,
        action: "surround",
        type: "xui-column-responsive-1",
        slot : "-col-0",
        icon: "mdi-table-column",
        title: "Surround in column");
    ret.add(act);

    act = ObjectAction(
        xid: designFirstNoSlot.slotInfo.xid!,
        action: "surround",
        type: "xui-tabs",
        slot : "-tab-item-0",
        icon: "mdi-tab",
        title: "Surround in tab");
    ret.add(act);
    
    act = ObjectAction(
        xid: designFirstNoSlot.slotInfo.xid!,
        action: "surround",
        type: "xui-block",
        slot : "-block",
        icon: "mdi-checkbox-blank-outline",
        title: "Surround in block");
    ret.add(act);

    act = ObjectAction(
        xid: designFirstNoSlot.slotInfo.xid!,
        action: "surround",
        type: "xui-over-1",
        slot : "-col-0",
        icon: "mdi-move-resize-variant",
        title: "Add over");
    ret.add(act);
    
    act = ObjectAction(
        xid: designFirstNoSlot.slotInfo.xid!,
        action: "surround",
        type: "xui-badge-1",
        slot : "-col-0",
        icon: "mdi-checkbox-blank-badge-outline",
        title: "Add badge");
    ret.add(act);
  }
}

///------------------------------------------------------------------------------------------
class JSDesignInfo {
  late String xid;
  late String xidSlot;
  List<TreeSlot> listPath = [];
  List<TreeSlot> listChildPath = [];
  List<TreeSlot> listConditionalPath = [];
  var bufData = StringBuffer();
  var bufTemplate = StringBuffer();
}
