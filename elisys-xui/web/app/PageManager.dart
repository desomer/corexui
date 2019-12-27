
import '../core/XUIEngine.dart';
import '../core/XUIFactory.dart';
import '../core/parser/HTMLReader.dart';
import '../core/parser/ProviderAjax.dart';

class PageManager {

  Future<String> getHtml( XUIContext ctx, String uri, String xid) async {

    var provider = ProviderAjax();

    var reader = HTMLReader(uri, provider);

    var bufferHtml = XUIHtmlBuffer();


    var xuiEngine = XUIEngine();
    await xuiEngine.start(reader, ctx);
    await xuiEngine.toHTMLString(bufferHtml, xid, ctx);

    return Future.value(bufferHtml.html.toString());
  }
  
}
