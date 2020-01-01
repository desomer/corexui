import './core/XUIEngine.dart';
import './core/XUIFactory.dart';
import './core/parser/HTMLReader.dart';
import './core/parser/ProviderAjax.dart';

class PageManager {
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
}


