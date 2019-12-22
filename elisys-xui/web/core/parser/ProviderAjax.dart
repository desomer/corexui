import 'dart:html';

import '../XUIEngine.dart';

class ProviderAjax extends Provider {
  String path;

  ProviderAjax();

  getAjax(String id) {
    return HttpRequest.getString(id);
  }

  @override
  Future<String> getResourceFutur(String id) {
    return HttpRequest.getString(id);
  }
}
