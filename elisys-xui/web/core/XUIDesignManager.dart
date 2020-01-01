import './XUIEngine.dart';
import './XUIFactory.dart';
import './parser/HTMLReader.dart';
import './parser/ProviderAjax.dart';

class XUIDesignManager {
  var xuiEngine = XUIEngine();

  Future<String> getHtml(XUIContext ctx, String uri, String xid) async {
    var provider = ProviderAjax();

    var reader = HTMLReader(uri, provider);
    await xuiEngine.initialize(reader, ctx);

    var bufferHtml = XUIHtmlBuffer();
    await xuiEngine.toHTMLString(bufferHtml, xid, ctx);

    return Future.value(bufferHtml.html.toString());
  }

  Future<String> reloadHtml(XUIContext ctx, String uri, String xid) async {
    var bufferHtml = XUIHtmlBuffer();
    await xuiEngine.toHTMLString(bufferHtml, xid, ctx);

    return Future.value(bufferHtml.html.toString());
  }

  Future addDesign(String id, String template) async {
    await xuiEngine.addDesign(id, template);

    return Future.value();
  }

  void changeProperty(String xid, String variable, dynamic value) {
    print( "${xid} a changer l'attribut ${variable} par ${value}");
    var xuiModel = xuiEngine.xuiFile.designs[xid].sort(xuiEngine.xuiFile.context).first;
    print( xuiModel.elemXUI.propertiesXUI[variable].content);
    xuiModel.elemXUI.propertiesXUI[variable].content = value;
  }

  JSDesignInfo getJSDesignInfo(String id, String idslot) {
    var ret = JSDesignInfo();
    var designs = xuiEngine.getDesignInfo(id, idslot);

    int i = 0;
    for (var design in designs) {
      // todo creer le template avec xui  (fichier templateEditor.html)

      var titleCmp = design?.docInfo?.name ?? design.slotInfo.docId;
      String header = "<v-subheader class='elevation-2 xui-style-prop'>" +
          titleCmp +
          "</v-subheader><v-divider></v-divider>";
      ret.bufTemplate.write(header);

      for (var varCmp in design?.docInfo?.variables ?? const []) {
        var istr = i.toString();
        String template;
        if (varCmp.editor == "bool")
          template =
              "<v-switch dense class='ma-2' hide-details inset :label='data[" +
                  istr +
                  "].label' v-model='data[" +
                  istr +
                  "].value'></v-switch>";
        else if (varCmp.editor == "int")
          template =
              "<v-text-field class='ma-1' hide-details clearable type='number' min='0' max='99' :label='data[" +
                  istr +
                  "].label' v-model='data[" +
                  istr +
                  "].value'></v-text-field>";
        else
          template =
              "<v-text-field class='ma-1' hide-details clearable :label='data[" +
                  istr +
                  "].label' v-model='data[" +
                  istr +
                  "].value'></v-text-field>";

        ret.bufTemplate.write(template);
        if (i > 0) ret.bufData.write(",");

        var value = null;
        if (design.slotInfo.elementHTML?.propertiesXUI != null) {
          var valInCmp =
              (design.slotInfo.elementHTML?.propertiesXUI[varCmp.id]?.content);
          if (valInCmp != null && varCmp.editor == "bool")
            value = valInCmp;
          else if (valInCmp != null) value = "\"" + valInCmp + "\"";
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
            value +
            ", \"value_orig\":" +
            value +
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

class JSDesignInfo {
  var bufPath = StringBuffer();
  var bufData = StringBuffer();
  var bufTemplate = StringBuffer();
}
