
@JS("_app")
library xuiapp;

import 'package:js/js.dart';

import 'app/core.dart';

@JS()
external void load(obj);


void main() async {

  String str = await FirstApp().start();

  load(str);
}