@JS("\$xui")
library xuiapp;

import 'package:js/js.dart';

import 'app/core.dart';

@JS()
external void load(obj);


@JS('refresh')
external set _refresh(void Function() f);

void refresh() async {
  String str = await FirstApp().start();
  print(str);
  load(str);
}

void main() async {
  _refresh= allowInterop(refresh);

  String str = await FirstApp().start();
 // print(str);
  load(str);
}
