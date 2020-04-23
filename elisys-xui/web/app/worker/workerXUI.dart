@JS("\$xui")
library xuiapp;

import 'dart:html';
import 'package:js/js.dart';
import 'dart:js';

import '../../core/XUIDesignManager.dart';
import '../../core/XUIJSInterface.dart';

@JS('self')
external DedicatedWorkerGlobalScope get self;

@JS('doEvent')
external set _doEvent(void Function(String) f);

main() {
  _doEvent = allowInterop(doEvent);
  print("((((((((((((((object)))))))))))))))))");
  context["\$xuiworker"]
      .callMethod("doPromiseJS", ["setDesignProperties", "a"]);
}

doEvent(String json) async {
  print(json);

  FileDesignInfo fileInfo = FileDesignInfo();
  fileInfo.file = 'app/frame1.html';
  fileInfo.xid = 'root';

  print(fileInfo.xid);

  //var ctx = XUIContext(MODE_DESIGN);
  //var designManager = XUIDesignManager();

  //await designManager.initEngine('app/frame1.html', ctx);

 // String str = await designManager.getHtml(ctx, 'app/frame1.html', 'root');
  //print(str);
  print(json);
}

XUIDesignManager getDesignManager(FileDesignInfo fileInfo) {
  return XUIDesignManager.getDesignManager(fileInfo);
}
