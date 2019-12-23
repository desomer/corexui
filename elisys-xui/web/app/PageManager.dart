
import '../core/XUIEngine.dart';
import '../core/XUIFactory.dart';
import '../core/parser/HTMLReader.dart';
import '../core/parser/ProviderAjax.dart';

class PageManager {

  Future<String> getHtml(String uri, String xid) async {

    var provider = ProviderAjax();

    var reader = HTMLReader(uri, provider);

    var bufferHtml = XUIHtmlBuffer();

    await XUIEngine().start(reader, bufferHtml, xid);

    return Future.sync(() => bufferHtml.html.toString());
  }
  
}
