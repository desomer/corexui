
import '../core/XUIEngine.dart';
import '../core/XUIFactory.dart';
import '../core/parser/HTMLReader.dart';
import '../core/parser/ProviderAjax.dart';

class FirstApp {
  Future<String> start() async {

    var provider = ProviderAjax();

    var reader = HTMLReader('app/frame1.html', provider);

    var bufferHtml = XUIHtmlBuffer();

    await XUIEngine().start(reader, bufferHtml, "rootweb");

    return Future.sync(() => bufferHtml.html.toString());
  }
}
