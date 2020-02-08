import 'dart:collection';

import './XUIEngine.dart';
import './XUIFactory.dart';
import './parser/HTMLReader.dart';
import './parser/ProviderAjax.dart';
import 'XUIActionManager.dart';
import 'element/XUIProperty.dart';

class XUIDesignManager {
  var xuiEngine = XUIEngine();

  ///------------------------------------------------------------------------------------------
  Future<String> getHtml(XUIContext ctx, String uri, String xid) async {
    var provider = ProviderAjax();

    var reader = HTMLReader(uri, provider);
    await xuiEngine.initialize(reader, ctx);

    var bufferHtml = XUIHtmlBuffer();
    await xuiEngine.toHTMLString(bufferHtml, xid, ctx);

    return Future.value(bufferHtml.html.toString());
  }

  ///------------------------------------------------------------------------------------------
  Future<String> reloadHtml(XUIContext ctx, String uri, String xid) async {
    var bufferHtml = XUIHtmlBuffer();
    await xuiEngine.toHTMLString(bufferHtml, xid, ctx);

    return Future.value(bufferHtml.html.toString());
  }

  ///------------------------------------------------------------------------------------------
  Future addDesign(String id, String template) async {
    print("add design on ${id}  template ${template}");
    await XUIActionManager(xuiEngine).addDesign(id, template);
    return Future.value();
  }

  void removeDesign(String id, String template) {
    XUIActionManager(xuiEngine).removeDesign(id, template);
  }

  ///------------------------------------------------------------------------------------------
  Future changeProperty(String xid, String variable, dynamic value) async {
    print("${xid} a changer l'attribut ${variable} par ${value}");
    var listDesign = xuiEngine.xuiFile.designs[xid];
    if (listDesign == null) {
      await addDesign(xid, "<xui-design></xui-design>");
      listDesign = xuiEngine.xuiFile.designs[xid];
    }

    var xuiModel = listDesign.sort(xuiEngine.xuiFile.context).first;
    //print(xuiModel.elemXUI.propertiesXUI[variable].content);
    xuiModel.elemXUI.propertiesXUI ??= HashMap<String, XUIProperty>();
    if (xuiModel.elemXUI.propertiesXUI[variable] == null) {
      xuiModel.elemXUI.propertiesXUI[variable] = XUIProperty(null);
    }
    xuiModel.elemXUI.propertiesXUI[variable].content = value;

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

    return ret;
  }

  ///------------------------------------------------------------------------------------------
  JSDesignInfo getJSDesignInfo(String id, String idslot) {
    var ret = JSDesignInfo();
    var designs = xuiEngine.getDesignInfo(id, idslot);
    ret.xid = id;

    int i = 0;
    for (var design in designs) {
      // todo creer le template avec xui  (fichier templateEditor.html)

      var titleCmp = design?.docInfo?.name ?? design.slotInfo.docId;
      String header = "<v-subheader @click='\$xui.selectCmp(\"${design.slotInfo.xid}\", \"${design.slotInfo.xid}\")' class='elevation-2 xui-style-prop'>" +
          titleCmp + "<v-spacer></v-spacer><v-icon>mdi-dots-horizontal</v-icon>"
          "</v-subheader><v-divider></v-divider>";
      ret.bufTemplate.write(header);

      for (var varCmp in design?.docInfo?.variables ?? const []) {
        var istr = i.toString();
        String template;
        if (varCmp.editor == "bool") {
          template =
              "<v-switch dense class='ma-2' hide-details inset :label='data[" +
                  istr +
                  "].label' v-model='data[" +
                  istr +
                  "].value'></v-switch>";
        } else if (varCmp.editor == "int") {
          template =
              "<v-text-field class='ma-1' hide-details clearable type='number' min='0' max='99' :label='data[" +
                  istr +
                  "].label' v-model='data[" +
                  istr +
                  "].value'></v-text-field>";
        } else {
          template =
              "<v-text-field class='ma-1' hide-details clearable :label='data[" +
                  istr +
                  "].label' v-model='data[" +
                  istr +
                  "].value'></v-text-field>";
        }

        ret.bufTemplate.write(template);
        if (i > 0) ret.bufData.write(",");

        var value;
        if (design.slotInfo.elementHTML?.propertiesXUI != null) {
          var valInCmp =
              (design.slotInfo.elementHTML?.propertiesXUI[varCmp.id]?.content);
          if (valInCmp != null && varCmp.editor == "bool") {
            value = valInCmp;
          } else if (valInCmp != null) value = "\"" + valInCmp + "\"";
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
            "}");
        i++;
      }
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
  var bufPath = StringBuffer();
  var bufData = StringBuffer();
  var bufTemplate = StringBuffer();
}
