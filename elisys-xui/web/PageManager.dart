
import './core/XUIEngine.dart';
import './core/XUIFactory.dart';
import './core/parser/HTMLReader.dart';
import './core/parser/ProviderAjax.dart';

class PageManager {

  var xuiEngine = XUIEngine();

  Future<String> getHtml( XUIContext ctx, String uri, String xid) async {

    var provider = ProviderAjax();

    var reader = HTMLReader(uri, provider);
    await xuiEngine.start(reader, ctx);

    var bufferHtml = XUIHtmlBuffer();
    await xuiEngine.toHTMLString(bufferHtml, xid, ctx);

    return Future.value(bufferHtml.html.toString());
  }

  Future<String> reloadHtml( XUIContext ctx, String uri, String xid) async {

    var bufferHtml = XUIHtmlBuffer();

    await xuiEngine.addDesign("grid-1-row-2-col-0", "<xui-design><h1>test</h1></xui-design>");
    await xuiEngine.addDesign("onglet-tab-1", "<xui-design>Titre</xui-design>");
    await xuiEngine.addDesign("grid-1-row-1", "<xui-design xui-nb=\"5\"></xui-design>");

    await xuiEngine.toHTMLString(bufferHtml, xid, ctx);

    return Future.value(bufferHtml.html.toString());
  }
  
}
