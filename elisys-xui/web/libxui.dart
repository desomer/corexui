@JS("\$xui")
library xuiapp;

import 'package:js/js.dart';
import 'PageManager.dart';
import 'core/XUIEngine.dart';


@JS()
external void load(obj);

@JS()
external void changeTemplate(obj);

@JS('refresh')
external set _refresh(void Function() f);

void refresh() async {
  String str = await pageManager.reloadHtml(XUIContext(MODE_TEMPLATE), 'app/frame1.html', 'root');
//  print(str);
  changeTemplate(str);
}

//document.querySelector("#rootFrame").contentWindow.postMessage({ "json_example": true }, "*");

PageManager pageManager=PageManager();

void main() async {
  _refresh = allowInterop(refresh);

 String str = await pageManager.getHtml(XUIContext(MODE_DESIGN), 'app/frame1.html', 'root');
  // print(str);
  load(str);
}
