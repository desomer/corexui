import 'dart:html';

import '../XUIEngine.dart';

class ProviderAjax extends Provider {
  late String path;

  ProviderAjax();

  getAjax(String id) {
    return HttpRequest.getString(id);
  }

  @override
  Future<String> getResourceFutur(String id) {
    return HttpRequest.getString(id);
  }
}
