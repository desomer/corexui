@JS("\$xui")
library xuiapp;

import 'package:js/js.dart';
import 'app/PageManager.dart';


@JS()
external void load(obj);

@JS()
external void changeTemplate(obj);

@JS('refresh')
external set _refresh(void Function() f);

void refresh() async {
  String str = await PageManager().getHtml('app/frame1.html', 'root-designer');
//  print(str);
  changeTemplate(str);
}

//document.querySelector("#rootFrame").contentWindow.postMessage({ "json_example": true }, "*");

void main() async {
  _refresh = allowInterop(refresh);

 String str = await PageManager().getHtml('app/frame1.html', 'root');
  // print(str);
  load(str);
}
